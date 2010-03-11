require 'armchair'
require 'classinatra/client'
require 'latex/symbol'
require 'detexify/base'

module Detexify
  
  class LatexApp < Base
    set :classifier, Classinatra::Client.at(ENV['CLASSIFIER'] || 'http://localhost:3000')
    set :couch, Armchair.new(ENV['COUCH'] || 'http://localhost:5984/detexify')
    set :symbols, Latex::Symbol::ExtendedList
  end
  
end