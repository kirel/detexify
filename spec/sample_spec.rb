require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'couchrest'
require 'sample'

describe Detexify::Sample do
  before do
    @db = CouchRest.database! TESTCOUCH
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
  end
  
  after do
    @db.delete!
  end
  
  it "can be created and saved" do
    sample = Detexify::Sample.on(@db).new :strokes => @strokes, :feature_vector => [], :symbol_id => @symbol.id
    lambda { sample.create! }.should_not raise_error     
  end
end

describe Detexify::MiniSampleContainer do
  
  before(:each) do
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
    @sample = Detexify::Sample.new :strokes => @strokes, :feature_vector => [1], :symbol_id => @symbol.id
    @othersample = Detexify::Sample.new :strokes => @strokes, :feature_vector => [2], :symbol_id => @symbol.id
    @limit = 1
    @c = Detexify::MiniSampleContainer.new @limit
  end
  
  it "can add a sample (as Minisample)" do
    (@c << @sample).for_id(@sample.symbol_id).should === [Detexify::MiniSample.new(@sample)]
  end
  
  it "should not add more that it's limit" do
    (@c << @sample << @othersample).for_id(@sample.symbol_id).should have(@limit).samples
  end

  it "should contain the most recently added sample" do
    (@c << @sample << @othersample).for_id(@sample.symbol_id).should include(@othersample)
  end

  it "should drop the oldest sample" do
    (@c << @sample << @othersample).for_id(@sample.symbol_id).should_not include(@sample)
  end
  
end