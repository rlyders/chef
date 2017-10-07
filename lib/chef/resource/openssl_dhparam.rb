#
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
    # @author Charles Johnson <charles@chef.io>
    # generates dhparam.pem files. If a valid dhparam.pem file is found at the specified location,
    # no new file will be created. If a file is found at the specified location but it is not a valid
    # dhparam file, it will be overwritten.
    class OpensslDhparam < Chef::Resource
      require "openssl"

      resource_name :openssl_dhparam

      property :path,        String, name_property: true
      property :key_length,  equal_to: [1024, 2048, 4096, 8192], default: 2048
      property :generator,   equal_to: [2, 5], default: 2
      property :owner,       String, default: "root"
      property :group,       String, default: node["root_group"]
      property :mode,        [Integer, String], default: "0640"

      action :create do
        return if dhparam_pem_valid?(new_resource.path)

        converge_by("Create a dhparam file #{new_resource.path}") do
          dhparam_content = gen_dhparam(new_resource.key_length, new_resource.generator).to_pem

          declare_resource(:file, new_resource.name) do
            action :create
            owner new_resource.owner
            group new_resource.group
            mode new_resource.mode
            sensitive true
            content dhparam_content
          end
        end
      end

      action_class do
        # Check if the dhparam.pem file exists
        # Verify the dhparam.pem file contains a key
        def dhparam_pem_valid?(dhparam_pem_path)
          return false unless ::File.exist?(dhparam_pem_path)
          dhparam = OpenSSL::PKey::DH.new File.read(dhparam_pem_path)
          dhparam.params_ok?
        end

        # generate a dhparam file
        def gen_dhparam(key_length, generator)
          raise ArgumentError, "Key length must be a power of 2 greater than or equal to 1024" unless key_length_valid?(key_length)
          OpenSSL::PKey::DH.new(key_length, generator)
        end
      end
    end
  end
end
