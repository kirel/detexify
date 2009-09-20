require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'classifiers'

describe Detexify::KnnClassifier do

  before do
    @data = 1
    @sample = Detexify::Sample.new(:"1", 1)
    @extractor = lambda { |i| i } # identity
    @measure = lambda { |i,j| (i - j).abs }
    @classifier = Detexify::KnnClassifier.new @extractor, @measure
  end
    
  it "should train a sample" do
    lambda { @classifier.train(@sample.id, @sample.data) }.should_not raise_error
  end
  
  describe "with some samples trained" do
    
    before do
      (1..10).each do |i|
        sample = Detexify::Sample.new(:"#{i}", i)
        @classifier.train(sample.id, sample.data)
      end
    end
    
    it "should classify a new sample" do
      lambda { @classifier.classify(@data) }.should_not raise_error
    end

    it "should return results ordered by their score" do
      res = @classifier.classify(@data)
      # # mapping to hit[:score] as sort_by is not stable
      res.map { |hit| hit[:score] }.should === res.sort_by { |hit| hit[:score] }.map { |hit| hit[:score] }
    end

    it "should limit the results if requested" do
      res = @classifier.classify(@data, :limit => 1)
      res.should have(1).elements    
    end

    it "should skip results if requested" do
      res = @classifier.classify(@data)
      skip = @classifier.classify(@data, :skip => 1)
      skip.should === res[1..-1]
    end

    it "should limit the results if also skipped" do
      res = @classifier.classify(@data, :limit => 1, :skip => 1)
      res.should have(1).elements
    end

    it "should skip results if also limited" do
      res = @classifier.classify(@data, :limit => 2)
      skip = @classifier.classify(@data, :skip => 1, :limit => 1)
      skip.should === res[1, 1]    
    end
    
  end
  
end