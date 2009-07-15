require 'spec'
require 'spec/interop/test'
require 'rack/test'

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'app'

def app
  Sinatra::Application
end

set :environment, :test

describe 'The Sinatra classifier' do
  include Rack::Test::Methods

  before do
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @uri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUAAAD///+l2Z/dAAAAM0lEQVR4nGP4/5/h/1+G/58ZDrAz3D/McH8yw83NDDeNGe4Ug9C9zwz3gVLMDA/A6P9/AFGGFyjOXZtQAAAAAElFTkSuQmCC'
    CLASSIFIER.stub!(:train)
  end

  it "classifies a wellformed request" do
    CLASSIFIER.should_receive(:classify).and_return ['foo', 'bar']
    post '/classify', :url => @uri, :strokes => JSON(@strokes)
    last_response.should be_ok
    r = JSON last_response.body
    r.should be_a(Hash)
    %w(best all).each do |key|
      r.should have_key(key)
    end
  end
  
  it "trains a wellformed request" do
    CLASSIFIER.should_receive(:train)
    post '/train', {:id => @symbol.id, :url => @uri, :strokes => JSON(@strokes)}
    last_response.should be_ok
  end
  
  it "won't train illegal ids" do
    CLASSIFIER.should_not_receive(:train)
    post '/train', {:id => 'bullshit', :url => @uri, :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train without strokes" do
    CLASSIFIER.should_not_receive(:train)
    post '/train', {:id => @symbol.id, :url => @uri}
    last_response.status.should == 403
  end

  it "won't train malformed strokes" do
    CLASSIFIER.should_not_receive(:train)
    post '/train', {:id => @symbol.id, :url => @uri, :strokes => 'malformed'}
    last_response.status.should == 403
  end

  it "won't train without url" do
    CLASSIFIER.should_not_receive(:train)
    post '/train', {:id => @symbol.id, :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train malformed url" do
    CLASSIFIER.should_not_receive(:train)
    post '/train', {:id => @symbol.id, :url => 'malformed', :strokes => JSON(@strokes)}
    last_response.status.should == 403
  end

  it "won't train unreachable url" do
    CLASSIFIER.should_not_receive(:train)
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