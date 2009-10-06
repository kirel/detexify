require 'spec/rake/spectask'
require 'symbol_task'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  #t.rcov = false
end

SymbolTask.new