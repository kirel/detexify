require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'decision_tree'

describe DecisionTree do
  
  before do
    @struct = Struct.new :color, :taste
    @sample = Sample.new :klass, @struct.new(:red, :tasty)
    @t = DecisionTree.new [lambda { |e| e.color }, lambda { |e| e.taste }]
  end
  
  it "should add samples to the tree" do
    lambda { @t << @sample }.should_not raise_error
  end
  
  it "should return the right subset" do
    samples = [
      [[:red, :tasty]],
      [[:blue, :nasty]]*2,
      [[:green, :sweet]]*3
    ].map { |a| a.map { |b| Sample.new :klass, @struct.new(*b) } }
    
    samples.each do |a|
      a.each do |s|
        @t << s        
      end
    end
    
    samples.each do |a|
      @t.call(a.first.data).should == a
    end
  end
  
end
