require 'matrix'

module Enumerable
  def sum
    inject { |s,e| s+e }
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
  
  def euclidean_distance x, y
    v = x-y
    v.inner_product(v)**0.5
  end
  
end
