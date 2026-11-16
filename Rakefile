# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'shellwords'

Rake::TestTask.new(:minitest) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

# Async mode runs on CRuby only (the gem refuses to load elsewhere), so the
# suite always runs under padded_cell.
desc 'Run the test suite with padded_cell'
task :test do
  sh 'padded_cell', *Shellwords.split(ENV.fetch('TESTOPTS', ''))
end

task default: :test
