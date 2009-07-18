require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'couchrest'
require 'sample'

describe Detexify::Sample do
  before do
    Detexify::Sample::database.recreate!
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
  end
  
  after do
    Detexify::Sample::database.recreate!
  end
  
  it "can be created" do
    sample = Detexify::Sample.new :strokes => @strokes, :feature_vector => [], :symbol_id => @symbol.id
    lambda { sample.create! }.should_not raise_error     
  end
end