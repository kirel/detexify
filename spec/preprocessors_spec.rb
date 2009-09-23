require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'preprocessors'

describe Detexify::Preprocessors::Strokes::EquidistantPoints do
  
  def distance p1, p2
    (p1-p2).r
  end
  
  before do
    @distance = 0.01
    @pre = Detexify::Preprocessors::Strokes::EquidistantPoints.new :distance => @distance
    @stroke = [Vector[1,1], Vector[-1,-3], Vector[-1,-1]]
  end
  
  it "should make points in strokes equidistantly distributed" do
    stroke = @pre.process @stroke
    previous = nil
    stroke.each do |point|
      if previous
        # not using be_close because distance in cusps can be smaller
        distance(previous, point).should <= @distance + @distance/100.0 # TODO there should be a matcher
        previous = point
      else
        previous = point
      end
    end
  end
  
  it "should nearly preserve the start and the end" do
    stroke = @pre.process @stroke
    [:first, :last].each do |m|
      distance(stroke.send(m), @stroke.send(m)).should be_close(0, @distance)      
    end
  end
  
  it "should not die on duplicate points" do
    stroke = nil
    lambda { stroke = @pre.process [Vector[0,0]]*10 }.should_not raise_error
    stroke.should == [Vector[0,0]]
  end
  
  it "should not fail on duplicate points" do
    @pre.process([Vector[0,0]]*10 + [Vector[1,1]]).should have_at_least(2).elements
  end
      
end

describe Detexify::Preprocessors::Strokes::ToImage do
  
  it "should create an image from the strokes"
  
end
