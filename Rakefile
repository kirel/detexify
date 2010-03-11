begin
  # Require the preresolved locked set of gems.
  require ::File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'spec/rake/spectask'
require 'symbol_task'
require 'populate_task'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  #t.rcov = false
end

SymbolTask.new

PopulateTask.new