require 'sample'

class DecisionTree
  
  # TODO http://en.wikipedia.org/wiki/ID3_algorithm
   
  def initialize deciders
    @deciders = deciders
    @tree = {}
  end
  
  def << sample # TODO should be able to add to multiple subtrees
    t = @tree
    @deciders[0..-2].each do |d|
      branch = d.call sample.data
      t[branch] ||= {}
      t = t[branch]
    end
    branch = @deciders.last.call sample.data
    t[branch] ||= []
    t[branch] << sample
  end
  
  # prune samples and return a smaller subset
  def call data
    t = @tree
    @deciders[0..-2].each do |d|
      branch = d.call data
      t = t[branch]
      raise 'Can not classify' if t.nil?
    end
    branch = @deciders.last.call data
    t[branch] || raise('Can not classify')
  end
  
end