#
# Copyright:: 2015-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/resource"
require "shellwords"

class Chef
  class Resource
    # The rhsm_register resource performs the necessary tasks to register
    # your host with RHSM or your local Satellite server.
    #
    # @since 14.0
    class RhsmRegister < Chef::Resource
      resource_name :rhsm_register

      property :activation_key,        [String, Array]
      property :satellite_host,        String
      property :organization,          String
      property :environment,           String
      property :username,              String
      property :password,              String
      property :auto_attach,           [TrueClass, FalseClass], default: false
      property :install_katello_agent, [TrueClass, FalseClass], default: true
      property :force,                 [TrueClass, FalseClass], default: false

      action :register do
        unless new_resource.satellite_host.nil? || registered_with_rhsm?
          remote_file "#{Chef::Config[:file_cache_path]}/katello-package.rpm" do
            source "http://#{new_resource.satellite_host}/pub/katello-ca-consumer-latest.noarch.rpm"
            action :create
            notifies :install, "yum_package[katello-ca-consumer-latest]", :immediately
            not_if { katello_cert_rpm_installed? }
          end

          yum_package "katello-ca-consumer-latest" do
            options "--nogpgcheck"
            source "#{Chef::Config[:file_cache_path]}/katello-package.rpm"
            action :nothing
          end

          file "#{Chef::Config[:file_cache_path]}/katello-package.rpm" do
            action :delete
          end
        end

        execute "Register to RHSM" do
          sensitive new_resource.sensitive
          command register_command
          action :run
          not_if { registered_with_rhsm? }
        end

        yum_package "katello-agent" do
          action :install
          only_if { new_resource.install_katello_agent && new_resource.satellite_host }
        end
      end

      action :unregister do
        execute "Unregister from RHSM" do
          command "subscription-manager unregister"
          action :run
          only_if { registered_with_rhsm? }
          notifies :run, "execute[Clean RHSM Config]", :immediately
        end

        execute "Clean RHSM Config" do
          command "subscription-manager clean"
          action :nothing
        end
      end

      action_class do
        def registered_with_rhsm?
          cmd = Mixlib::ShellOut.new("subscription-manager status", env: { LANG: node["rhsm"]["lang"] })
          cmd.run_command
          !cmd.stdout.match(/Overall Status: Unknown/)
        end

        def katello_cert_rpm_installed?
          cmd = Mixlib::ShellOut.new("rpm -qa | grep katello-ca-consumer")
          cmd.run_command
          !cmd.stdout.match(/katello-ca-consumer/).nil?
        end

        def activation_keys
          Array(new_resource.activation_key)
        end

        def register_command
          command = %w{subscription-manager register}

          unless activation_keys.empty?
            raise "Unable to register - you must specify organization when using activation keys" if new_resource.organization.nil?

            command << activation_keys.map { |key| "--activationkey=#{Shellwords.shellescape(key)}" }
            command << "--org=#{Shellwords.shellescape(new_resource.organization)}"
            command << "--force" if new_resource.force

            return command.join(" ")
          end

          if new_resource.username && new_resource.password
            raise "Unable to register - you must specify environment when using username/password" if new_resource.environment.nil? && using_satellite_host?

            command << "--username=#{Shellwords.shellescape(new_resource.username)}"
            command << "--password=#{Shellwords.shellescape(new_resource.password)}"
            command << "--environment=#{Shellwords.shellescape(new_resource.environment)}" if using_satellite_host?
            command << "--auto-attach" if new_resource.auto_attach
            command << "--force" if new_resource.force

            return command.join(" ")
          end

          raise "Unable to create register command - you must specify activation_key or username/password"
        end

        def using_satellite_host?
          !new_resource.satellite_host.nil?
        end
      end
    end
  end
end
