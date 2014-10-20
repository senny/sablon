require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.libs.push 'test'
  t.verbose = true
end

task default: :test
