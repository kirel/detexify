module ImageMoments
  module_function
  
  # function can be a matrix or a lambda
  # (anything that implements [](i,j))
  def moment(i,j,function,rangeX,rangeY)
    m = 0.0
    rangeX.each do |x|
      rangeY.each do |y|
        m += (x**i)*(y**j)*function[x,y]
      end
    end
    m
  end
    
  def moments(function,rangeX,rangeY)
    mem = []
    lambda do |i,j|
      mem[i] ||= []
      mem[i][j] ||= moment(i,j,function,rangeX,rangeY)
    end
  end
    
  def centroid(function,rangeX,rangeY)
    m = moments(function,rangeX,rangeY)
    [m[1,0]/m[0,0],m[0,1]/m[0,0]]
  end

  def centralmoment(i,j,function,rangeX,rangeY)
    c = centroid(function,rangeX,rangeY)
    m = 0.0
    rangeX.each do |x|
      rangeY.each do |y|
        m += ((x-c[0])**i)*((y-c[1])**j)*function[x,y]
      end
    end
    m
  end

  def centralmoments(function,rangeX,rangeY)
    mem = []
    lambda do |i,j|
      mem[i] ||= []
      mem[i][j] ||= centralmoment(i,j,function,rangeX,rangeY)
    end
  end
  
  def eta(function,rangeX,rangeY)
    m = centralmoments(function,rangeX,rangeY)
    lambda do |i,j|
      #raise "i+j >= 2 must hold" if i+j<2
      m[i,j]/(m[0,0]**(1+(i+j)/2))
    end
  end
  
  def hu_moments(function,rangeX,rangeY)
    e = eta(function,rangeX,rangeY)
    {
      1 => e[2,0]+e[0,2],
      2 => (e[2,0]-e[0,2])**2 + 2*(e[1,1]**2),
      3 => (e[3,0]-3*e[1,2])**2+(3*e[2,1]-e[0,3])**2,
      4 => (e[3,0]+e[1,2])**2 + (e[2,1]+e[0,3])**2,
      5 => (e[3,0]-3*e[1,2])*(e[3,0]+e[1,2])*((e[3,0]+e[1,2])**2-(e[2,1]+e[0,3])**2)+(3*e[2,1]-e[0,3])*(e[2,1]+e[0,3])*(3*(e[3,0]+e[1,2])**2-(e[2,1]+e[0,3])**2),
      6 => (e[2,0]-e[0,2])*((e[3,0]+e[1,2])**2-(e[2,1]+e[0,3])**2)+4*e[1,1]*(e[3,0]+e[1,2])*(e[2,1]+e[0,3]),
      7 => (3*e[2,1]-e[0,3])*(e[3,0]+e[1,2])*((e[3,0]+e[1,2])**2-3*(e[2,1]+e[0,3])**2)-(e[3,0]-3*e[1,2])*(e[2,1]+e[0,3])*(3*(e[3,0]+e[1,2])**2-(e[2,1]+e[0,3])**2),
    }
  end
  
  def hu_vector(function,rangeX,rangeY)
    Vector[*hu_moments(function,rangeX,rangeY).values]
  end
end
