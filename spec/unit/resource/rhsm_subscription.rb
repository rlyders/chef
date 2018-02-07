#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

require "spec_helper"

describe Chef::Resource::RhsmSubscription do

  let(:resource) { Chef::Resource::RhsmSubscription.new("foo") }

  it "has a resource name of :rhsm_subscription" do
    expect(resource.resource_name).to eql(:rhsm_subscription)
  end

  it "has a default action of attach" do
    expect(resource.action).to eql([:attach])
  end

  it "the pool_id property is the name property" do
    expect(resource.pool_id).to eql("foo")
  end
end
