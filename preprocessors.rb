require 'matrix'
require 'math'

module Detexify

  module Preprocessors

    module Strokes

      # TODO class FitInside
      #   DEFAULT_OPTIONS = { :x => 0.0..1.0, :y => 0.0..1.0 }
      #   def process strokes

      # TODO class LineDensity 

      # TODO Tests needed!
      class EquidistantPoints

        DEFAULT_OPTIONS = { :distance => 0.01 }

        def initialize options = {}
          @options = DEFAULT_OPTIONS.update(options)
        end

        def process stroke
          # convert to equidistant point distribution
          equidistant_stroke = [stroke.first] # need first point anyway
          distance_left = @options[:distance]
          previous = nil
          stroke.each do |point|
            if previous
              p = Vector.elements(previous.values_at('x', 'y'))
              n = Vector.elements(point.values_at('x', 'y'))
              v = n - p
              norm = v.r
              # add new points
              while norm > distance_left
                p = p + v * (distance_left/norm)
                previous = {'x' => p[0], 'y' => p[1]}
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

      end # class EquidistantPoints

    end # module Strokes

  end # module Preprocessors

end