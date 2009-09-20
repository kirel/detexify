require 'math'
require 'matrix'
require 'preprocessors'

module Detexify

  module Extractors

    module Strokes

      class BoundingBox

        def call strokes
          # TODO push this into preprocessors.rb
          # maximally fit into [0,1]x[0,1]
          first_point = strokes.first.first
          left, right, top, bottom = [0,0,1,1].map { |c| first_point[c] }  # TODO!
          strokes.each do |stroke|
            stroke.each do |point|
              left   = point[0] if point[0] < left # x
              right  = point[0] if point[0] > right # x
              bottom = point[1] if point[1] < bottom # y
              top    = point[1] if point[1] > top # y
            end
          end
          return [left, right, top, bottom].map { |i| i.to_f }
        end

      end

      class PointDensity

        def initialize *boxes # box = { 'x' => left..right, 'y' => bottom..top }
          @boxes = boxes
        end

        def call strokes
          count = [0] * @boxes.size
          strokes.each do |stroke|
            stroke.each do |point|
              @boxes.each_with_index do |box, i|
                count[i] += 1 if box['x'].include?(point[0]) && box['y'].include?(point[1])
              end
            end
          end
          return count.map { |i| i.to_f }
        end

      end

      class DirectionalHistogramFeatures
        # return startdirection, enddirection, #N, #NE, #E, ...

        def call strokes
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
                p = previous #Vector.elements(previous.values_at('x', 'y'))
                n = point #Vector.elements(point.values_at('x', 'y'))
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
          res.map { |i| i.to_f }
        end # def

      end # class DirectionalHistogramFeatures

      class Features

        def call strokes
          strokes = strokes.map { |st| st.map { |p| p.dup } } # s.dup enough?
          # preprocess strokes

          # TODO chop off heads and tails
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Chop.new(:points => 5, :degree => 180).process(stroke)            
          # end

          # TODO smooth out points (avarage over three points)
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Smooth.new.process(stroke)            
          # end

          left, right, top, bottom = Detexify::Extractors::Strokes::BoundingBox.new.call(strokes)

          # TODO push this into a preprocessor
          # computations for next step
          height = top - bottom
          width = right - left
          ratio = width/height
          long, short = ratio > 1 ? [width, height] : [height, width]
          offset =  if ratio > 1
            Vector[0.0, (1.0 - short/long)/2.0]
          else
            Vector[(1.0 - short/long)/2.0, 0.0]
          end

          # move left and bottom to zero, scale to fit and then center
          strokes = strokes.map do |stroke|
            stroke.map do |point|
              ((point - Vector[left, bottom]) * (1.0/long)) + offset
            end
          end          

          # convert to equidistant point distributon
          strokes = strokes.map do |stroke|
            Detexify::Preprocessors::Strokes::EquidistantPoints.new(:distance => 0.01).process(stroke)            
          end

          # FIXME I've lost the timestamps here. Dunno if I want to keep them

          extractors = []
          # extract features
          # - directional histogram features
          extractors << Detexify::Extractors::Strokes::DirectionalHistogramFeatures.new
          # - start direction
          # - end direction
          # startdirection, enddirection = Extractors::StartEndDirection.new.process(strokes)
          # - start/end position
          # - point density
          boxes = [
            {'x' => (0...0.4), 'y' => (0..1)},
            {'x' => (0.4...0.6), 'y' => (0..1)},
            {'x' => (0.6..1), 'y' => (0..1)},
            {'y' => (0...0.4), 'x' => (0..1)},
            {'y' => (0.4...0.6), 'x' => (0..1)},
            {'y' => (0.6..1), 'x' => (0..1)},
          ]
          extractors << Detexify::Extractors::Strokes::PointDensity.new(*boxes)
          # - aspect ratio
          # - number of strokes
          extractors << Proc.new { |s| (s.size*10).to_f }
          # TODO add more features
          return Vector.elements extractors.map { |e| e.call(strokes) }.flatten
        end

      end # class OnlineFeatures

    end # module Strokes

  end # module Extractors

end