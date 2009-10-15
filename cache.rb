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

require 'memcache'

class Cache

  def self.cache_dir
    @@cache_dir ||= 'cache'
  end

  def self.fetch(key, &block)
    @@cache ||= {}

    # Return the cached value if already in memory.
    return @@cache[key] unless @@cache[key].nil?

    # Try to load from file.
    @@cache[key] = File.open(File.join(cache_dir, key), 'rb'){ |io| Marshal.load(io) } rescue nil
    return @@cache[key] unless @@cache[key].nil?

    # Barring all else, perform the operation to obtain value to cache.
    @@cache[key] = block.call
    File.open(File.join(cache_dir, key), 'wb'){ |f| Marshal.dump(@@cache[key], f) }

    @@cache[key]
  end
end