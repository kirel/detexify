require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'couch'

describe Couch do
  
  before(:each) do
    @dburl = 'http://localhost:5984/test/'
    @couch = Couch.new @dburl
    @doc = {'some' => 'doc'}
  end
  
  after(:each) do
    begin
      RestClient.delete(@dburl)
    rescue RestClient::ResourceNotFound
    end
  end
  
  it "should respond to http methods" do
    %w(get put post delete).each do |method|
      @couch.should respond_to(method)
    end
  end
  
  it "should create the database" do
    @couch.create!
    lambda { RestClient.get(@dburl) }.should_not raise_error(RestClient::ResourceNotFound)
  end
  
  it "should insert documents" do
    RestClient.should_receive(:post).with(@dburl, JSON(@doc))
    @couch << @doc
  end
  
  describe "with some documents in it" do
    
    before(:each) do
      @num = 345
      @couch.create!
      @docs = (1..@num).map { |i| { 'number' => i } }
      @docs.each { |doc| @couch << doc }
    end
    
    it "should know the numbers" do
      @couch.size.should == @num
    end
    
    it "should iterate over each document" do
      docs = @docs.dup
      @couch.each do |doc|
        docs.delete(docs.detect { |d| d['number'] == doc['number']})
      end
      docs.should be_empty
    end
    
  end
  
end