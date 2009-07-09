require 'spec'
require 'spec/interop/test'
require 'rack/test'

require File.join(File.dirname(__FILE__), '/spec_helper')

require 'app'

def app
  Sinatra::Application
end

set :environment, :test

describe 'The Sinatra classifier' do
  include Rack::Test::Methods

  before do
    Detexify::Sample::database.recreate!
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @uri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUAAAD///+l2Z/dAAAAM0lEQVR4nGP4/5/h/1+G/58ZDrAz3D/McH8yw83NDDeNGe4Ug9C9zwz3gVLMDA/A6P9/AFGGFyjOXZtQAAAAAElFTkSuQmCC'
    # TODO just mock the shit out of Detexify::Sample
    # FIXME remove coupling here!
    v = Detexify::Classifier.new.extract_features nil, @strokes
    sample = Detexify::Sample.new :strokes => @strokes, :feature_vector => v.to_a, :symbol_id => @symbol.id
    sample.create!
  end

  it "classifies a wellformed request" do
    post '/classify', :url => @uri, :strokes => JSON(@strokes)
    last_response.should be_ok
    # verify structure of response
    # [:best => {:symbol => {...}, :score => score }, {:symbol => {...}, :score => score } ]
    r = JSON(last_response.body)
    r.should be_a(Hash)
    %w(best all).each do |key|
      r.should have_key(key)
      r[key].should be_an(Array)
      r[key].should_not be_empty
      r[key].each do |element|
        element.should be_a(Hash)
        element.should have_key('symbol')
        element.should have_key('score')
      end      
    end
  end
  
  it "trains a wellformed request" do
    post '/train', {:id => @symbol.id, :url => @uri, :strokes => JSON(@strokes)}
    last_response.should be_ok
  end
  
  it "won't train illegal ids" do
    post '/train', {:id => 'bullshit', :url => @uri, :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train without strokes" do
    post '/train', {:id => @symbol.id, :url => @uri}
    last_response.status.should == 403
  end

  it "won't train malformed strokes" do
    post '/train', {:id => @symbol.id, :url => @uri, :strokes => 'malformed'}
    last_response.status.should == 403
  end

  it "won't train without url" do
    post '/train', {:id => @symbol.id, :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train malformed url" do
    post '/train', {:id => @symbol.id, :url => 'malformed', :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train unreachable url" do
    post '/train', {:id => @symbol.id, :url => 'http://un.reach.able/url', :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end
  
  it "lists symbols as json" do
    get '/symbols'
    last_response.should be_ok
    # verify structure of response
    # [{id:..., command:..., textmode:..., ...}, ...]
    r = JSON(last_response.body)
    r.should be_a(Array)
    r.each do |element|
      element.should be_a(Hash)
      %w(id command mathmode textmode samples).each do |key|
        element.should have_key key        
      end
    end
  end
  
end