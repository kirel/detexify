require 'spec'
require 'spec/interop/test'
require 'sinatra/test'
require File.join(File.dirname(__FILE__), '/spec_helper')

require File.join(File.dirname(__FILE__), '../app')

set :environment, :test

describe 'The Sinatra classifier' do
  include Sinatra::Test

  it "classifies"
  
  it "trains"
  
  it "lists symbols as json"
  
end