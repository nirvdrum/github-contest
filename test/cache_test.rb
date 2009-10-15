# Copyright 2009 Kevin J. Menard Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'test_helper'
require 'cache'
require 'memcache'

class CacheTest < Test::Unit::TestCase

  def test_fetch
    cache = {}
    MemCache.stubs(:new).returns(cache)

    # Check that upon initial access, we get the value from the block.
    val = Cache.fetch('key') { 7 }
    assert_equal 7, val

    # Check that upon subsequent access, we get the already written value.
    new_val = Cache.fetch('key') { 9 }
    assert_equal 7, val  
  end

end