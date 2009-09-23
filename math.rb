require 'matrix'

module Enumerable
  def sum(*args, &block)
    if block_given?
      map &block
    else
      self
    end.inject(*args) { |sum, x| sum + x }
  end
end

module Statistics

  module_function

  def sample_mean *vectors
    vectors.sum * (1.0/vectors.size)
  end

  ## for n dimensional data we need n+1 samples to have a regular covariance matrix
  def sample_covariance_matrix *vectors
    n = vectors.first.size - 1
    num = vectors.size - 1
    m = sample_mean(*vectors)
    a = []
    0.upto(n) do |i|
      0.upto(n) do |j|
        sum = (0..num).collect { |k| (vectors[k][i]-m[i])*(vectors[k][j]-m[j]) }.sum
        a[i] ||= [] 
        a[i][j] = sum * (1.0/num)
      end
    end
    c = Matrix[*a]
  end

  def mahalanobis_distance x, *samples
    raise "sample covariance matrix will be singular - for dimension #{x.size} you need at least #{x.size+1} samples" if samples.size <= x.size
    m = sample_mean(*samples)
    ((x-m).inner_product(sample_covariance_matrix(*samples).inverse*(x-m)))**0.5
  end

end

module MyMath

  module_function

  def euclidean_distance x, y
    (x-y).r
  end

  def orientation v
    v = v*(1.0/v.r) # normalize
    x, y = v.to_a
    cos = Math::acos(x)*8.0/Math::PI
    sin = Math::asin(y)*8.0/Math::PI
    case
    when cos >= 3 && sin >= 3 && sin < 5
      :north
    when cos >= 1 && cos < 3 && sin >= 1 && sin < 3
      :northeast
    when cos < 1 && sin < 1 && sin >= -1
      :east
    when cos >= 1 && cos < 3 && sin < -1 && sin >= -3
      :southeast
    when cos >= 3 && cos < 5 && sin < -3
      :south
    when cos >= 5 && cos < 7 && sin >= -3 && sin < -1
      :southwest
    when cos >= 7 && sin >= -1 && sin < 1
      :west
    when cos >= 5 && cos < 7 && sin >= 1 && sin < 3
      :northwest
    else
      :none # v.r == 0 => x,y == NaN
    end
    
  end

end