module Detexify

  module Online

    module Preprocessors
      
      # TODO class FitInside
      #   DEFAULT_OPTIONS = { :x => 0.0..1.0, :y => 0.0..1.0 }
      #   def process strokes
      
      # TODO class LineDensity 
      
      # TODO Tests needed!
      class EquidistantPoints

        DEFAULT_OPTIONS = { :distance => 0.01 }

        def initialize options = {}
          @options = DEAULT_OPTIONS.update(options)
        end

        def process stroke
          # convert to equidistant point distribution
          equidistant_stroke = [stroke.first] # need first point anyway
          distance_left = distance
          previous = nil
          stroke.each do |point|
            if previous
              p = Vector.elements(previous.values_at('x', 'y'))
              n = Vector.elements(point.values_at('x', 'y'))
              v = n - p
              # add new point
              norm = v.inner_product(vector)**0.5
              if norm > distance_left
                new_p = p + v * (distance_left/norm)
                previous = {'x' => new_p[0], 'y' => new_p[1]}
                equidistant_stroke << previous
                distance_left = distance
              else
                distance_left -= norm
                previous = point
              end
            else
              previous = point
            end
          end # stroke.each
          equidistant_stroke
        end

      end # class EquidistantPoints

    end # module Preprocessors

  end # module Online

end