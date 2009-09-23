require 'matrix'
require 'math'
require 'extractors'

module Detexify

  module Preprocessors

    module Strokes

      # TODO class FitInside
      #   DEFAULT_OPTIONS = { :x => 0.0..1.0, :y => 0.0..1.0 }
      #   def call strokes

      # TODO class LineDensity 

      class EquidistantPoints

        DEFAULT_OPTIONS = { :distance => 0.01 }

        def initialize options = {}
          @options = DEFAULT_OPTIONS.update(options)
        end

        def call strokes
          strokes.map do |stroke|
            # convert to equidistant point distribution
            equidistant_stroke = [stroke.first] # need first point anyway
            distance_left = @options[:distance]
            previous = nil
            stroke.each do |point|
              if previous
                p = previous
                n = point
                v = n - p
                norm = v.r # FIXME might be zero
                # add new points
                while norm > distance_left
                  p = p + v * (distance_left/norm)
                  previous = p
                  equidistant_stroke << previous
                  distance_left = @options[:distance]
                  v = n - p
                  norm = v.r            
                end
                distance_left -= norm # NOTE this does not distribute equidistantly - exact solution needs square computations
                previous = point
              else
                previous = point
              end
            end # stroke.each
            equidistant_stroke            
          end
        end

      end # class EquidistantPoints
      
      # take strokes and make an (rmagick?) image out of it
      class ToImage
        
      end # class StrokesToImage
      
      class SizeNormalizer
        
        # TODO options
        
        def call strokes
          left, right, top, bottom = Detexify::Extractors::Strokes::BoundingBox.new.call(strokes)

          # TODO push this into a preprocessor
          # computations for next step
          height = top - bottom
          width = right - left
          ratio = width/height
          long, short = ratio > 1 ? [width, height] : [height, width]
          offset = case
          when long.zero? # all points in one spot
            Vector[0.5, 0.5]
          when ratio > 1
            Vector[0.0, (1.0 - short/long)/2.0]
          else # ratio <= 1
            Vector[(1.0 - short/long)/2.0, 0.0]
          end
          
          # move left and bottom to zero, scale to fit and then center
          strokes.map do |stroke|
            stroke.map do |point|
              if long.zero? # all points in one spot
                point - Vector[left, bottom] + offset
              else
                ((point - Vector[left, bottom]) * (1.0/long)) + offset
              end
            end
          end
        end
        
      end

    end # module Strokes
    
    class Pipe
      
      def initialize *preprocessors
        @preprocessors = *preprocessors
      end
      
      def call strokes
        @preprocessors.inject(strokes) do |s, pre|
          pre.call s
        end
      end
      
    end

  end # module Preprocessors

end