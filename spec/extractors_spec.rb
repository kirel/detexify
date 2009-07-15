require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'extractors'

describe Detexify::Extractors::Strokes::BoundingBox do
  
  before do
    @ex = Detexify::Extractors::Strokes::BoundingBox.new
  end
  
  it "should calculate the bounding box of one stroke" do
    strokes = [[{'x'=>1,'y'=>1}, {'x'=>-1,'y'=>-1}]]
    @ex.call(strokes).should == [-1,1,1,-1]
  end

  it "should calculate the bounding box of more strokes" do
    strokes = [[{'x'=>1,'y'=>1}], [{'x'=>-1,'y'=>-1}]]
    @ex.call(strokes).should == [-1,1,1,-1]
  end

  it "should calculate the bounding box of a single point" do
    strokes = [[{'x'=>1,'y'=>1}]]
    @ex.call(strokes).should == [1,1,1,1]
  end
    
end

describe Detexify::Extractors::Strokes::DirectionalHistogramFeatures do
    
end

describe Detexify::Extractors::Strokes::PointDensity do
  
  before do
    @ex = Detexify::Extractors::Strokes::PointDensity.new({'x' => (0..1), 'y' => (0..1) }, {'x' => (1..2), 'y' => (1..2) })
  end
  
  it "should calculate the point density" do
    strokes = [[{'x'=>0.5,'y'=>0.5}], [{'x'=>1.5,'y'=>1.5}], [{'x'=>0.5,'y'=>1.5}], [{'x'=>1.5,'y'=>1.5}]]
    @ex.call(strokes).should == [1,2]
  end
    
end