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

Cache.instance_eval do
  def self.clear
    @@cache.clear
  end
end