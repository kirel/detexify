require '../lib/image_moments'

describe ImageMoments do
  
  before(:each) do
    @f = lambda { |x,y| 1 }
  end
  
  it "should calculate moment correctly" do
    # 1*1*1+1*1*1+1*1*1+1*1*1
    ImageMoments.moment(0,0,@f,1..2,1..2).should == 4
    # 1*1*1+2*1*1+1*1*1+1*2*1
    ImageMoments.moment(0,1,@f,1..2,1..2).should == 6
    ImageMoments.moment(1,0,@f,1..2,1..2).should == 6
  end
  
  it "should give correct moment calculator" do
    m = ImageMoments.moments(@f,1..2,1..2)
    m[0,0].should == 4
    m[1,0].should == 6
    m[0,1].should == 6
    m[1,1].should == 9
  end
  
  it "should calculate controid correctly" do
    ImageMoments.centroid(@f,1..2,1..2).should == [6.0/4,6.0/4]
  end
  
  it "should calculate central moments correctly" do
    ImageMoments.centralmoment(0,0,@f,1..2,1..2).should == ImageMoments.moment(0,0,@f,1..2,1..2)
    ImageMoments.centralmoment(1,0,@f,1..2,1..2).should == 0
    ImageMoments.centralmoment(0,1,@f,1..2,1..2).should == 0
  end

  it "should give correct central moment calculator" do
    m = ImageMoments.centralmoments(@f,1..2,1..2)
    m[0,0].should == ImageMoments.moment(0,0,@f,1..2,1..2)
    m[1,0].should == 0
    m[0,1].should == 0
  end
  
  it "should give hu moments" do
    lambda do
      h = ImageMoments.hu_moments(@f,1..2,1..2)
      1.upto(7) { |n| h[1] }
    end.should_not raise_error
  end
  
end