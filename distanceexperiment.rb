# TODO remove

require 'rmagick'
require 'image_moments'
require 'statistics'
include ImageMoments
include Statistics
### get file from commandline, read it, output hu-moments

def img2hu img
  img.quantize(2, Magick::GRAYColorspace, Magick::NoDitherMethod)
  a = (0..(img.rows-1)).collect { |n| img.get_pixels(0,n,img.columns,1).collect { |p| p.intensity } }
  m = Matrix[*a]
  hu_vector(m, 0..(m.column_size-1), 0..(m.row_size-1) )
end

hus = ARGV.collect do |file|
  puts file
  img = Magick::Image::read(file).first
  puts "   Format: #{img.format}"
  puts "   Geometry: #{img.columns}x#{img.rows}"
  puts "   Depth: #{img.depth} bits-per-pixel"
  puts "   Colors: #{img.number_colors}"
  puts "   Filesize: #{img.filesize}"
  puts "-"*80
  # make a Matrix out of the pixel values
  hu = img2hu(img)
  puts hu.inspect
  puts "="*80
  [file, hu]
end

a = []
0.upto(hus.size-2) do |n|
  (n+1).upto(hus.size-1) do |m|
    puts "Distance between #{hus[n][0]} and #{hus[m][0]} is #{euclidean_distance(hus[n][1],hus[m][1])}"
    a << ["#{hus[n][0]} <-> #{hus[m][0]}", euclidean_distance(hus[n][1],hus[m][1])]
  end
end
a = a.sort_by { |e| e[1] }
puts "Sorted by distance:"
a.each_with_index { |e,i| puts "#{i}. #{e[0]}: #{e[1]}" }