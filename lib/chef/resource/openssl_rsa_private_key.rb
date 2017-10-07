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
    # generates rsa private key files. If a valid rsa key file can be opened at the specified location,
    # no new file will be created. If the RSA key file cannot be opened, either because it does not exist
    # or because the password to the RSA key file does not match the password in the recipe, it will be overwritten.
    class OpensslRsaPrivateKey < Chef::Resource
      require "openssl"

      resource_name :openssl_rsa_private_key

      property :path,        String, name_property: true
      property :key_length,  equal_to: [1024, 2048, 4096, 8192], default: 2048
      property :key_pass,    String
      property :key_cipher,  String, default: "des3", equal_to: valid_ciphers
      property :owner,       String, default: "root"
      property :group,       String, default: node["root_group"]
      property :mode,        [Integer, String], default: "0640"
      property :force,       [true, false], default: false

      action :create do
        return if new_resource.force || priv_key_file_valid?(new_resource.path, new_resource.key_pass)

        converge_by("create #{new_resource.key_length} bit RSA key #{new_resource.path}") do
          if new_resource.key_pass
            unencrypted_rsa_key = gen_rsa_priv_key(new_resource.key_length)
            rsa_key_content = encrypt_rsa_key(unencrypted_rsa_key, new_resource.key_pass, new_resource.cipher)
          else
            rsa_key_content = gen_rsa_priv_key(new_resource.key_length).to_pem
          end

          declare_resource(:file, new_resource.path) do
            action :create
            owner new_resource.owner
            group new_resource.group
            mode new_resource.mode
            sensitive true
            content rsa_key_content
          end
        end
      end

      action_class do
        def gen_rsa_key(key_length)
          raise ArgumentError, "Key length must be a power of 2 greater than or equal to 1024" unless key_length_valid?(key_length)

          OpenSSL::PKey::RSA.new(key_length)
        end

        # Key manipulation helpers
        # Returns a pem string
        def encrypt_rsa_key(rsa_key, key_password)
          raise TypeError, "rsa_key must be a Ruby OpenSSL::PKey::RSA object" unless rsa_key.is_a?(OpenSSL::PKey::RSA)
          raise TypeError, "RSA key password must be a string" unless key_password.is_a?(String)

          cipher = OpenSSL::Cipher::Cipher.new("des3")
          rsa_key.to_pem(cipher, key_password)
        end
      end
    end
  end
end
