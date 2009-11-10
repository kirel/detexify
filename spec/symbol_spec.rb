require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'erb'
require 'uri'
require 'symbol'

describe Latex::Symbol do
  
  before do
    @symbol = Latex::Symbol.new :command => '\command', :package => 'package', :fontenc => 'fontenc'
  end

  it "should have properties command, package, fontenc, mathmode, textmode" do
    [:command, :package, :fontenc, :textmode, :mathmode].each do |m|
      @symbol.should respond_to(m)
    end
  end
  
  it "should have the propertie uri" do
    @symbol.should respond_to(:uri)
    lambda { URI.parse(@symbol.uri) }.should_not raise_error(URI::InvalidURIError)
  end
  
  it "should require command and rest is optional" do
    lambda { Latex::Symbol.new :command => '\command' }.should_not raise_error
    lambda { Latex::Symbol.new }.should raise_error(ArgumentError)
  end
  
  it "should provide defaults for mathmode and textmode" do
    @symbol.textmode.should be_true
    @symbol.mathmode.should be_false
  end
    
  it "should have a good to_s" do
    @symbol.to_s.should == '\\command (package, fontenc)'
  end

  it "should have to_hash" do
    @symbol.to_hash.should == { :command => '\command', :package => 'package', :fontenc => 'fontenc', :textmode => true, :mathmode => false, :id => @symbol.id}
  end
end

describe 'Latex::Symbol::List' do

  TEMPLATE = ERB.new open(File.join(File.dirname(__FILE__), '..', 'template.tex.erb')).read
  
  it "should have all different ids" do
    ids = Latex::Symbol::List.map { |symbol| symbol.id }
    ids.size.should == ids.uniq.size
  end

  Latex::Symbol::List.each do |symbol|
    it "should compile #{symbol} without error" do
      tmp = File.join(File.expand_path(File.dirname(__FILE__)),'tmp')
      Dir.mkdir tmp unless File.exist? tmp
      dvi = File.join(tmp, 'test.dvi')
      File.delete(dvi) if File.exist?(dvi)
      tempfile = File.new(File.join(tmp, 'test.tex'), 'w+')
      # setup variables
      @packages = ''
      @packages << "\\usepackage{#{symbol[:package]}}\n" if symbol[:package]
      @packages << "\\usepackage[#{symbol[:fontenc]}]{fontenc}\n" if symbol[:fontenc]
      @command = symbol.mathmode ? "$#{symbol.command}$" : symbol.command
      # write symbol to tempfile
      tempfile.puts TEMPLATE.result(binding)
      tempfile.close
      system("latex -interaction=batchmode -output-directory=#{tmp} #{tempfile.path} >/dev/null").should be_true
      File.should be_exist(dvi)
      # TODO maybe parse logs
      # put into before/after!
      File.delete(tempfile.path)
      File.delete(dvi)
    end
  end
  
end