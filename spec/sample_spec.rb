require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'couchrest'
require 'sample'

describe Detexify::Sample do
  before do
    Detexify::Sample::database.recreate!
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
  end
  
  it "can be created and found thereafter" do
    sample = Detexify::Sample.new '_id' => @symbol.id, :strokes => @strokes, :feature_vector => []
    sample.create
    Detexify::Sample.get(@symbol.id).should === sample
  end
end