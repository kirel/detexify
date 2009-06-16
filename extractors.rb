module Detexify

  module Online

    module Extractors
      
      class BoundingBox
        
        def initialize options = {}
          
        end
        
        def extract strokes
          # TODO push this into preprocessors.rb
          # maximally fit into [0,1]x[0,1]
          first_point = strokes.first.first
          left, right, top, bottom = %w(x x y y).map { |c| first_point[c] }  # TODO!
          strokes.each do |stroke|
            points.each do |point|
              left   = point[x] if point[x] < left
              right  = point[x] if point[x] > right
              bottom = point[y] if point[y] < bottom
              top    = point[y] if point[y] > top
            end
          end
          return left, right, top, bottom
        end
        
      end
      
      class DirectionalHistogramFeatures
        # return startdirection, enddirection, #N, #NE, #E, ...
        
        def extract strokes
          # 0 => n, 1 => ne, ...etc
          res = [0]*8
          strokes = strokes.each do |stroke|
            previous = nil
            stroke.each do |point|
              if previous
                # TODO DRY this up
                p = Vector.elements(previous.values_at('x', 'y'))
                n = Vector.elements(point.values_at('x', 'y'))
                v = n - p
                norm = v.inner_product(v)**0.5
                v = v*(1.0/norm)
                # now classify v
                # TODO factor this out as the chaincode
                x, y = v.to_a
                cos = Math::acos(x)*8.0/Math::PI
                sin = Math::asin(y)*8.0/Math::PI
                d = case
                when cos > 3 && sin > 3 && sin < 5
                  0 # north
                when cos > 1 && cos < 3 && sin > 1 && sin < 3
                  1 # northeast
                when cos < 1 && sin < 1 && sin > -1
                  2 # east
                when cos > 1 && cos < 3 && sin < -1 && sin > -3
                  3 # southeast
                when cos > 3 && cos < 5 && sin < -3
                  4 # south
                when cos > 5 && cos < 7 && sin > -3 && sin < -1
                  5 # southwest
                when cos > 7 && sin > -1 && sin < 1
                  6 # west
                when cos > 5 && cos < 7 && sin > 1 && sin < 3
                  7 # northwest
                end
                res[d] += 1
                previous = point                
              else
                previous = point
              end # if
            end # stroke.each
          end # strokes.each
          res
        end # def
        
      end # class DirectionalHistogramFeatures
      
    end # module Extractors

  end # module Online
  
end