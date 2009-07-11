require File.join(File.expand_path(File.dirname(__FILE__)), '../classifier')

describe Detexify::Classifier do

  before do
    Detexify::Sample::database.recreate!
    @classifier = Detexify::Classifier.new lambda { |strokes| rand 10 }, lambda { |data| rand 10 }
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @io = StringIO.new
    @sample = Detexify::Sample.new({
      :strokes => @strokes, :feature_vector => [0,0], :symbol_id => @symbol.id 
    })
    @sample.create!
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

  it "should train a legal symbol"
  
  it "should not train an illegal symbol"

  it "should regenerate features"

end