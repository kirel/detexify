require 'rubygems'
require 'spec/rake/spectask'

$LOAD_PATH << ::File.join(::File.dirname(__FILE__), 'lib')

require 'rake/symbol_task'
require 'rake/populate_task'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  #t.rcov = false
end

SymbolTask.new

PopulateTask.new
