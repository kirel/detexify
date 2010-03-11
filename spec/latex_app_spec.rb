require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

# require 'spec'
require 'rack/test'
require 'fakeweb'
require 'yaml'
require 'json'

TEST_CLASSIFIER = ENV['CLASSIFIER'] = 'http://localhost:11678'
# fake the classifier
resp = JSON( File.open( File.dirname(__FILE__)+'/fixtures/counts.yml' ) { |yf| YAML::load( yf ) } )
FakeWeb.register_uri :get, TEST_CLASSIFIER, :body => resp
resp = JSON( File.open( File.dirname(__FILE__)+'/fixtures/hits.yml' ) { |yf| YAML::load( yf ) } )
FakeWeb.register_uri :post, TEST_CLASSIFIER+'/classify', :body => resp
resp = JSON(:message => "Symbol was successfully trained.")
FakeWeb.register_uri :post, %r~#{TEST_CLASSIFIER}/train/.*~, :body => resp

require 'detexify/latex_app'

# Detexify::LatexApp.set :classifier

def app
  Detexify::LatexApp
end

class FakeCouch
  def << *args
    self
  end
end

app.set :environment, :test
app.set :couch, FakeCouch.new

describe 'Detexify' do
  include Rack::Test::Methods

  before do
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
  end
  
  it "classifies a wellformed request" do
    post '/classify', :strokes => JSON(@strokes)
    last_response.should be_ok
    r = JSON last_response.body
    r.should be_a(Array)
    r.each do |element|
      element.should be_a(Hash)
      %w(symbol score).each do |key|
        element.should have_key(key)
        element['symbol'].should be_a(Hash)
        %w(id command mathmode textmode uri).each do |key|
          element['symbol'].should have_key(key)
        end             
      end
    end
  end
  
  it "trains a wellformed request" do
    post '/train', {:id => @symbol.id, :strokes => JSON(@strokes)}
    last_response.should be_ok
  end
  
  it "won't train illegal ids" do
    post '/train', {:id => 'bullshit', :strokes => JSON(@strokes)}
    last_response.status.should == 400
  end

  it "won't train without strokes" do
    post '/train', {:id => @symbol.id}
    last_response.status.should == 400
  end

  it "won't train malformed strokes" do
    post '/train', {:id => @symbol.id, :strokes => 'malformed'}
    last_response.status.should == 400
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
      %w(id symbol samples).each do |key|
        element.should have_key(key)        
      end
      %w(command mathmode textmode uri).each do |key|
        element['symbol'].should have_key(key)
      end
    end
  end
  
  it "should limit the results if requested" do
    post '/classify', :strokes => JSON(@strokes), :limit => 1
    r = JSON last_response.body
    r.should have(1).elements    
  end

  it "should skip results if requested" do
    post '/classify', :strokes => JSON(@strokes)
    res = JSON last_response.body
    post '/classify', :strokes => JSON(@strokes), :skip => 1
    r = JSON last_response.body
    r.should == res[1..-1]
  end

  it "should limit the results if also skipped" do
    post '/classify', :strokes => JSON(@strokes), :skip => 1, :limit => 1
    r = JSON last_response.body
    r.should have(1).elements
  end

  it "should skip results if also limited" do
    post '/classify', :strokes => JSON(@strokes), :limit => 2
    res = JSON last_response.body
    post '/classify', :strokes => JSON(@strokes), :skip => 1, :limit => 1
    r = JSON last_response.body
    r.should === res[1, 1]    
  end
  
end