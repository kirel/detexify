require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'erb'
require 'uri'
require 'latex/symbol'

describe Latex::Symbol do
  
  before do
    @symbol = Latex::Symbol.new :command => '\command', :package => 'package', :fontenc => 'fontenc'
  end

  it "should have properties command, package, fontenc, mathmode, textmode" do
    [:command, :package, :fontenc, :textmode, :mathmode].each do |m|
      expect( @symbol ).to respond_to(m)
    end
  end
  
  it "should have the property uri" do
    expect( @symbol ).to respond_to(:uri)
    expect { URI.parse(@symbol.uri) }.not_to raise_error
  end
  
  it "should require command and rest is optional" do
    expect { Latex::Symbol.new :command => '\command' }.not_to raise_error
    expect { Latex::Symbol.new }.to raise_error(ArgumentError)
  end
  
  it "should provide defaults for mathmode and textmode" do
    expect( @symbol.textmode ).to be true
    expect( @symbol.mathmode ).to be false
  end

  it "should have a good to_s" do
    expect( @symbol.to_s ).to be == '\\command (package, fontenc)'
  end

  # TODO
  # it "should have to_hash" do
  #   @symbol.to_hash.should == { :command => '\command', :package => 'package', :fontenc => 'fontenc', :textmode => true, :mathmode => false, :id => @symbol.id}
  # end
end

describe 'Latex::Symbol::List' do

  TEMPLATE = ERB.new <<-LATEX #open(File.join(File.dirname(__FILE__), '..', 'template.tex.erb')).read
    \\documentclass[10pt]{article}
    \\usepackage[utf8]{inputenc}

    <%= @packages %>

    \\pagestyle{empty}
    \\begin{document}

    <%= @command %>

    \\end{document}
  LATEX

  it "should have all different ids" do
    ids = Latex::Symbol::List.map { |symbol| symbol.id }
    expect( ids.size ).to be == ids.uniq.size
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
      expect( system("latex -interaction=batchmode -output-directory=#{tmp} #{tempfile.path} >/dev/null") ).to be true
      expect( File ).to be_exist(dvi)
      # TODO maybe parse logs
      # put into before/after!
      File.delete(tempfile.path)
      File.delete(dvi)
    end
  end

end
