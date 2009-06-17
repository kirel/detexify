require File.join(File.expand_path(File.dirname(__FILE__)), '../math')

describe Statistics do
  
  include Statistics
  
  it "should give the correct sample mean" do
    x = Vector[2.0,2.0,2.0]
    y = Vector[0.0,0.0,0.0]
    sample_mean(x,y).should == Vector[1.0,1.0,1.0]
  end
  
  it "should give the correct sample covariance matrix" do
    x = Vector[0.0,0.0,0.0]
    y = Vector[0.0,0.0,0.0]
    z = Vector[0.0,0.0,0.0]
    sample_mean(x,y,z).should == x
    sample_covariance_matrix(x,y,z).should === Matrix.zero(3)
    # this is a shitty test!
  end
    
  it "should give a mahalanobis distance" do
    x = Vector[0.0,0.0,0.0]
    y = Vector[1.0,0.0,0.0]
    z = Vector[0.0,0.0,1.0]
    w = Vector[0.0,0.0,4.0]
    k = Vector[0.0,1.0,4.0]
    ## for n dimensional data we need n+1 samples!
    lambda { mahalanobis_distance(x,y,z,w) }.should raise_error
    lambda { mahalanobis_distance(x,y,z,w,k) }.should_not raise_error
  end
  
end

describe MyMath do
  
  include MyMath
  
  it "should measure euclidean distance correctly" do
    x = Vector[0.0,0.0,0.0]
    y = Vector[1.0,0.0,0.0]
    euclidean_distance(x,y).should == 1
  end
  
  it "should calculate orientation of a vector" do
    {
      :north => [0,1],
      :northeast => [1,1],
      :east => [1,0],
      :southeast => [1,-1],
      :south => [0,-1],
      :southwest => [-1,-1],
      :west => [-1,0],
      :northwest => [-1,1]
    }.each do |d, v|
      orientation(Vector.elements(v)).should == d      
    end
  end
  
end