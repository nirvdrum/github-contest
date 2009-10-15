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

$:.unshift "#{File.dirname(__FILE__)}" # Include the test directory in the path.
$:.unshift "#{File.dirname(__FILE__)}/ext/" # Include test extensions in the path.
$:.unshift "#{File.dirname(__FILE__)}/../" # Include the main app directory in the path.

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'ai4r'
require 'pp'

require 'ext/data_set'

require 'logger'
$LOG = Logger.new(STDOUT)
$LOG.level = Logger::FATAL
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

require 'cache'
Cache.instance_eval { @@cache = Hash.new }
Cache.instance_eval { @@cache_dir = "#{File.dirname(__FILE__)}/cache"}

Cache.instance_eval do
  def self.clear
    @@cache.clear
  end
end

require 'data_loader'
DataLoader.instance_eval { @@data_dir = "#{File.dirname(__FILE__)}/data" }