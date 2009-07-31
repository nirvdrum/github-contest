$:.unshift "#{File.dirname(__FILE__)}" # Include the test directory in the path.
$:.unshift "#{File.dirname(__FILE__)}/ext/" # Include test extensions in the path.
$:.unshift "#{File.dirname(__FILE__)}/../" # Include the main app directory in the path.

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'ai4r'
require 'pp'

require 'ext/data_set'