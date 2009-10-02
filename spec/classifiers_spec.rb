require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'sample'
require 'classifiers'

describe Classifiers::KnnClassifier do

  before do
    @data = 1
    @sample = Sample.new(:"1", 1)
    @extractor = lambda { |i| i } # identity
    @measure = lambda { |i,j| (i - j).abs }
    @classifier = Classifiers::KnnClassifier.new @extractor, @measure
  end
    
  it "should train a sample" do
    lambda { @classifier.train(@sample.id, @sample.data) }.should_not raise_error
  end
  
  describe "with some samples trained" do
    
    before do
      (1..10).each do |i|
        sample = Sample.new(:"#{i}", i)
        @classifier.train(sample.id, sample.data)
      end
    end
    
    it "should classify a new sample" do
      lambda { @classifier.classify(@data) }.should_not raise_error
    end

    it "should return results ordered by their score" do
      res = @classifier.classify(@data)
      # # mapping to hit[:score] as sort_by is not stable
      res.map { |hit| hit.score }.should === res.sort_by { |hit| hit.score }.map { |hit| hit.score }
    end
    
  end
  
end