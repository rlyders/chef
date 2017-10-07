#
# Copyright 2008-2017, Chef Software, Inc <legal@chef.io>
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
# Ported from the homebrew cookbook's Homebrew::Mixin owner helpers
#
# This lives here in Chef::Mixin because Chef's namespacing makes it
# awkward to use modules elsewhere (e.g., chef/provider/package/homebrew/owner)

require "openssl"

class Chef
  module Mixin
    module Openssl
      # Validation helpers
      def key_length_valid?(number)
        number >= 1024 && number & (number - 1) == 0
      end

      def key_file_valid?(key_file_path, key_password = nil)
        # Check if the key file exists
        # Verify the key file contains a private key
        return false unless ::File.exist?(key_file_path)
        key = OpenSSL::PKey::RSA.new File.read(key_file_path), key_password
        key.private?
      end
    end
  end
end
