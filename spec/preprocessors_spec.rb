require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'preprocessors'

describe Detexify::Preprocessors::Strokes::EquidistantPoints do
  
  def distance p1, p2
    (p1-p2).r
  end
  
  before do
    @distance = 0.01
    @pre = Detexify::Preprocessors::Strokes::EquidistantPoints.new :distance => @distance
    @strokes = [[Vector[1,1], Vector[-1,-3], Vector[-1,-1]]]
  end
  
  it "should make points in strokes equidistantly distributed" do
    strokes = @pre.call @strokes
    previous = nil
    strokes.each do |stroke|
      stroke.each do |point|
        if previous
          # not using be_close because distance in cusps can be smaller
          distance(previous, point).should <= (@distance + @distance/100.0) # TODO there should be a matcher
          previous = point
        else
          previous = point
        end
      end      
    end
  end
  
  it "should nearly preserve the start and the end" do
    strokes = @pre.call @strokes
    n, o = strokes.each, @strokes.each
    loop do
      ns, os = n.next, o.next
      [:first, :last].each do |m|
        distance(ns.send(m), os.send(m)).should be_close(0, @distance)      
      end      
    end
  end
  
  it "should work with a single point" do
    strokes = nil
    lambda { strokes = @pre.call [[Vector[0,0]]] }.should_not raise_error
    strokes.should == [[Vector[0,0]]]
  end
  
  it "should not die on duplicate points" do
    strokes = nil
    lambda { strokes = @pre.call [[Vector[0,0]]*10] }.should_not raise_error
    strokes.should == [[Vector[0,0]]]
  end
  
  it "should not fail on duplicate points" do
    @pre.call([[Vector[0,0]]*10 + [Vector[1,1]]])[0].should have_at_least(2).elements
  end
      
end

describe Detexify::Preprocessors::Strokes::ToImage do
  
  it "should create an image from the strokes"
  
end

describe Detexify::Preprocessors::Strokes::EquidistantPoints do
  
  before do
    @pre = Detexify::Preprocessors::Strokes::SizeNormalizer.new
    @strokes = [[Vector[1,1], Vector[-1,-3], Vector[-1,-1]]]
  end
  
  it "should normalize to [0,1]x[0,1]" do
    strokes = @pre.call @strokes
    strokes.each do |stroke|
      stroke.each do |point|
        point[0].should >= 0 
        point[0].should <= 1 
        point[1].should >= 0 
        point[1].should <= 1 
      end
    end
  end
  
  it "should center edge cases" do
    {
      [[Vector[1,1]]] => [[Vector[0.5,0.5]]],
      [[Vector[0,1], Vector[1,1]]] => [[Vector[0,0.5], Vector[1,0.5]]],
      [[Vector[1,0], Vector[1,1]]] => [[Vector[0.5,0], Vector[0.5,1]]]
    }.each do |before, after|
      @pre.call(before).should == after
    end
  end

end

describe Detexify::Preprocessors::Pipe do

  it "should pipe preprocessors together" do
    Detexify::Preprocessors::Pipe.new(lambda { |i| i+1 }, lambda { |i| i+1 }).call(1).should == 3
  end

  it "should call in the right order" do
    Detexify::Preprocessors::Pipe.new(lambda { |a| a.pop; a }, lambda { |a| a.push 2; a }).call([1]).should == [2]
  end
  
end
