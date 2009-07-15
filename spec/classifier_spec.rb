require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'classifier'

describe Detexify::Classifier do

  before do
    Detexify::Sample::database.recreate!
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @io = StringIO.new
    @io.stub!(:content_type).and_return('image/png')
    @sample = Detexify::Sample.new({
      :strokes => @strokes, :feature_vector => [0,0], :symbol_id => @symbol.id 
    })
    @sample.create!
    Detexify::Sample.count.should be(1)
    # instantiate now so that database is properly loaded
    @classifier = Detexify::Classifier.new lambda { |strokes| rand 10 }, lambda { |data| rand 10 }
    @classifier.wait_until_loaded
  end
  
  it "should load the database and have the correct sample count" do
    @classifier.samples.count.should be(1)
  end

  it "should classify a new sample" do
    best, all = @classifier.classify(@strokes, @io)
    best.should have(1).element
    all.should have(Latex::Symbol::List.size).elements

    # verify structure of response
    [best, all].each do |a|
      a.should be_an(Array)
      a.should_not be_empty
      a.each do |element|
        element.should be_a(Hash)
        element.should have_key(:symbol)
        element.should have_key(:score)
      end      
    end
  end
  
  it "should train a legal symbol" do
    lambda { @classifier.train(@symbol.id, @strokes, @io) }.should_not raise_error
  end
  
  it "should not train an illegal symbol and raise an appropriate error" do
    lambda { @classifier.train('fubar', @strokes, @io) }.should raise_error(Detexify::Classifier::IllegalSymbolId)
    lambda { @classifier.train(@symbol.id, 'fubar', @io) }.should raise_error(Detexify::Classifier::DataMessedUp)
    lambda { @classifier.train(@symbol.id, @strokes, 'fubar') }.should raise_error(Detexify::Classifier::DataMessedUp)
  end
  
  # FIXME this is a temporary spec - a need cleanup instead of limits
  describe "with a symbol trained to the limit" do
    
    before do
      # Symbol is in database once. Add another SAMPLE_LIMIT - 1 times.
      (Detexify::Classifier::SAMPLE_LIMIT-1).times { @classifier.train(@symbol.id, @strokes, @io) }
    end
    
    it "should not train that symbol again" do
      lambda { @classifier.train(@symbol.id, @strokes, @io) }.should raise_error(Detexify::Classifier::TooManySamples)
    end
    
  end
  
  it "have correct sample counts" do
    @classifier.sample_counts[@symbol.id].should == 1
    @classifier.count_samples(@symbol.id).should == 1
    @classifier.count_samples(@symbol).should == 1
    @classifier.sample_counts['foo'].should == 0 #IllegalSymbolId ?
    @classifier.count_samples('bar').should == 0
  end
  
  it "should regenerate features"

end