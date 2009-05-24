require 'image_moments'
require 'matrix'

include ImageMoments

m = Matrix[[1,2,3,4],[1,12,3,-3],[34,3,2,1],[4,3,2,1]]
m2 = m.transpose
hu = hu(m,0..3,0..3)
hu2 = hu(m,0..3,0..3)

puts m.inspect
1.upto(7) { |n| puts hu[n] }
puts "-"*20
puts m2.inspect
1.upto(7) { |n| puts hu2[n] }
