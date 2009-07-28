require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'classifier'

describe Detexify::Classifier do

  before do
    @db = CouchRest.database! TESTCOUCH
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @samples = Detexify::Sample.on(@db)
    @sample = @samples.new({
      :strokes => @strokes, :feature_vector => [0], :symbol_id => @symbol.id
    })
    @sample.create!
    #@samples.count.should be(1) # bug in couchrest TODO check if mattetti pulled my fix
    @classifier = Detexify::Classifier.new TESTCOUCH, lambda { |strokes| [rand 10] }
    @classifier.wait_until_loaded
  end
  
  after do
    @db.delete!
  end
  
  it "should load the database and have the correct sample count" do
    @classifier.samples.count.should be(1)
  end

  it "should classify a new sample" do
    res = @classifier.classify(@strokes)
    res.should have(Latex::Symbol::List.size).elements

    # verify structure of response
    res.should be_an(Array)
    res.each do |hit|
      hit.should be_a(Hash)
      hit.should have_key(:symbol)
      hit.should have_key(:score)
    end      
  end
  
  it "should limit the results if requested"
  
  it "should train a legal symbol" do
    lambda { @classifier.train(@symbol.id, @strokes) }.should_not raise_error
  end
  
  it "should not train an illegal symbol and raise an appropriate error" do
    lambda { @classifier.train('fubar', @strokes) }.should raise_error(Detexify::Classifier::IllegalSymbolId)
    lambda { @classifier.train(@symbol.id, 'fubar') }.should raise_error(Detexify::Classifier::DataMessedUp)
  end
  
  # FIXME this is a temporary spec - a need cleanup instead of limits
  describe "with a symbol trained to the limit" do
    
    before do
      # Symbol is in database once. Add another SAMPLE_LIMIT - 1 times.
      (Detexify::Classifier::SAMPLE_LIMIT-1).times { @classifier.train(@symbol.id, @strokes) }
    end
    
    it "should train that symbol again but don't load it into memory"
    
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