require 'rubygems'

$LOAD_PATH << ::File.join(::File.dirname(__FILE__), 'lib')

require 'rake/symbol_task'
require 'rake/populate_task'
require 'rake/benchmark_task'
require 'rake/setup_task'

SymbolTask.new
PopulateTask.new
BenchmarkTask.new
SetupTask.new

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  puts 'No rspec present.'
end
