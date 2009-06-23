require File.join(File.expand_path(File.dirname(__FILE__)), '../extractors')

describe Detexify::Online::Extractors::BoundingBox do
  
  before do
    @ex = Detexify::Online::Extractors::BoundingBox.new
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

describe Detexify::Online::Extractors::DirectionalHistogramFeatures do
    
end

describe Detexify::Online::Extractors::PointDensity do
  
  before do
    @ex = Detexify::Online::Extractors::PointDensity.new({'x' => (0..1), 'y' => (0..1) }, {'x' => (1..2), 'y' => (1..2) })
  end
  
  it "should calculate the point density" do
    strokes = [[{'x'=>0.5,'y'=>0.5}], [{'x'=>1.5,'y'=>1.5}], [{'x'=>0.5,'y'=>1.5}], [{'x'=>1.5,'y'=>1.5}]]
    @ex.call(strokes).should == [1,2]
  end
    
end