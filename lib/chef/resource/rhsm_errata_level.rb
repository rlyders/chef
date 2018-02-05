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

class Chef
  class Resource
    # The rhsm_errata_level resource will install all packages for all errata of
    # a certain security level. For example, you can ensure that all packages
    # associated with errata marked at a "Critical" security level are installed.
    #
    # @since 14.0
    class RhsmErrataLevel < Chef::Resource
      resource_name :rhsm_errata_level

      property :errata_level, String, name_property: true

      action :install do
        validate_errata_level!(new_resource.errata_level)
        yum_package "yum-plugin-security" do
          action :install
          only_if { node["platform_version"].to_i == 6 }
        end

        execute "Install any #{new_resource.errata_level} errata" do
          command "yum update --sec-severity=#{new_resource.errata_level.capitalize} -y"
          action :run
        end
      end

      action_class do
        def validate_errata_level!(level)
          raise "Invalid errata level: #{level.downcase} - must be: critical, moderate, important, or low" unless
            %w{critical moderate important low}.include?(level.downcase)
        end
      end
    end
  end
end
