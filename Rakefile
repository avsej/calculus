require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

task :default => :test
