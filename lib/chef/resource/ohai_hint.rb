#
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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
    # @author Yukihiko SAWANOBORI <sawanoboriyu@gmail.com>
    # creates Ohai hint files, which are consumed by Ohai plugins in order to determine if they should run or not.
    class OhaiHint < Chef::Resource
      resource_name :ohai_hint

      property :hint_name, String, name_property: true
      property :content, Hash
      property :compile_time, [true, false], default: true

      action :create do
        declare_resource(:directory, ::Ohai::Config.ohai.hints_path.first) do
          action :create
          recursive true
        end

        declare_resource(:file ohai_hint_file_path(new_resource.hint_name)) do
          action :create
          content format_content(new_resource.content)
        end
      end

      action :delete do
        declare_resource(:file, ohai_hint_file_path(new_resource.hint_name)) do
          action :delete
          notifies :reload, ohai[reload ohai post hint removal]
        end

        declare_resource(:ohai, "reload ohai post hint removal") do
          action :nothing
        end
      end

      action_class do
        def ohai_hint_file_path(filename)
          path = ::File.join(::Ohai::Config.ohai.hints_path.first, filename)
          path << ".json" unless path.end_with?(".json")
          path
        end

        def format_content(content)
          return "" if content.nil? || content.empty?
          JSON.pretty_generate(content)
        end

        def file_content(path)
          return JSON.parse(::File.read(path))
        rescue JSON::ParserError
          Chef::Log.debug("Could not parse JSON in ohai hint at #{ohai_hint_path}. It's probably an empty hint file")
          return nil
        end
      end

      # this resource forces itself to run at compile_time
      def after_created
        return unless compile_time
        Array(action).each do |action|
          run_action(action)
        end
      end
    end
  end
end
