require 'sample'

class DecisionTree
  
  # TODO http://en.wikipedia.org/wiki/ID3_algorithm
   
  def initialize deciders, limit = nil
    @deciders = deciders
    @tree = {}
    if limit
      @contailer = CappedContainer.new limit
      @leafs = Hash.new { |h,k| h[k] = [] }
    end
  end
  
  def << sample
    if @container && to_delete = @container.push(sample)
      @leafs[to_delete].each do |leaf|
        leaf.delete to_delete
      end
    end
    add_to_subtree @tree, sample, @deciders
    # t = @tree
    # @deciders[0..-2].each do |d|
    #   branch = d.call sample.data
    #   t[branch] ||= {}
    #   t = t[branch]
    # end
    # branch = @deciders.last.call sample.data
    # t[branch] ||= []
    # t[branch] << sample
  end
    
  # prune samples and return a smaller subset
  def call data
    merge_subtrees @tree, data, @deciders
    # t = @tree
    # @deciders[0..-2].each do |d|
    #   branch = d.call data
    #   t = t[branch]
    #   raise 'Can not classify' if t.nil?
    # end
    # branch = @deciders.last.call data
    # t[branch] || raise('Can not classify')
  end
  
  protected
  
  def add_to_subtree tree, sample, deciders
    deciders = deciders.dup
    d = deciders.shift
    if deciders.empty?
      leafs = d.call sample.data
      [*leafs].each do |leaf|
        tree[leaf] ||= []
        tree[leaf] << sample
        if @container # there is a limit
          @leafs[sample] << tree[leaf]
        end
      end
    else
      branches = d.call sample.data
      [*branches].each do |branch|
        tree[branch] ||= {}
        add_to_subtree tree[branch], sample, deciders # one less deciders
      end
    end
  end
  
  def merge_subtrees tree, data, deciders
    deciders = deciders.dup
    d = deciders.shift
    if deciders.empty?
      leafs = d.call data
      [*leafs].map do |leaf|
        tree[leaf] || []
      end
    else
      branches = d.call data
      [*branches].map do |branch|
        merge_subtrees tree[branch], data, deciders # one less deciders
      end.flatten
    end
  end
  
end