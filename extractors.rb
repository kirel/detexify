require 'matrix'
require 'math'

module Detexify

  module Online

    module Extractors

      class BoundingBox

        def extract strokes
          # TODO push this into preprocessors.rb
          # maximally fit into [0,1]x[0,1]
          first_point = strokes.first.first
          left, right, top, bottom = %w(x x y y).map { |c| first_point[c] }  # TODO!
          strokes.each do |stroke|
            stroke.each do |point|
              left   = point['x'] if point['x'] < left
              right  = point['x'] if point['x'] > right
              bottom = point['y'] if point['y'] < bottom
              top    = point['y'] if point['y'] > top
            end
          end
          return [left, right, top, bottom].map { |i| i.to_f }
        end

      end

      class PointDensity
        
        def initialize *boxes # box = { 'x' => left..right, 'y' => bottom..top }
          @boxes = boxes
        end

        def extract strokes
          count = [0] * @boxes.size
          strokes.each do |stroke|
            stroke.each do |point|
              @boxes.each_with_index do |box, i|
                count[i] += 1 if box['x'].include?(point['x']) && box['y'].include?(point['y'])
              end
            end
          end
          return count.map { |i| i.to_f }
        end

      end

      class DirectionalHistogramFeatures
        # return startdirection, enddirection, #N, #NE, #E, ...

        def extract strokes
          chaincodes = {
            :north => 0,
            :northeast => 1,
            :east => 2,
            :southeast => 3,
            :south => 4,
            :southwest => 5,
            :west => 6,
            :northwest => 7,
          } 

          res = [0]*8
          strokes = strokes.each do |stroke|
            previous = nil
            stroke.each do |point|
              if previous
                # TODO DRY this up
                p = Vector.elements(previous.values_at('x', 'y'))
                n = Vector.elements(point.values_at('x', 'y'))
                v = n - p
                # now classify v
                d = chaincodes[MyMath::orientation(v)]
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