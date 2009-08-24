require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the app.'
Rake::TestTask.new(:test) do |t|
  t.libs << '.'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end