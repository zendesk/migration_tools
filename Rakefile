require 'bundler/setup'
require 'bundler/gem_tasks'
require 'wwtd/tasks'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => 'wwtd:local'
