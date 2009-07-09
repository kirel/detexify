require 'couchrest'
require 'matrix'
require 'math'
require 'preprocessors'
require 'extractors'
require 'symbol'
require 'sample'

module Detexify
    
  class Classifier
    
    module Features
            
      # extract online fetures
      module Online
        
        module_function
        
        def extract s
          strokes = s.map { |st| st.map { |p| p.dup } } # s.dup enough?
          # preprocess strokes
          
          # TODO chop off heads and tails
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Chop.new(:points => 5, :degree => 180).process(stroke)            
          # end

          # TODO smooth out points (avarage over three points)
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Smooth.new.process(stroke)            
          # end
                    
          left, right, top, bottom = Detexify::Online::Extractors::BoundingBox.new.call(strokes)
          
          # TODO push this into a preprocessor
          # computations for next step
          height = top - bottom
          width = right - left
          ratio = width/height
          long, short = ratio > 1 ? [width, height] : [height, width]
          offset =  if ratio > 1
                      { 'x' => 0.0 , 'y' => (1.0 - short/long)/2.0 }
                    else
                      { 'x' => (1.0 - short/long)/2.0 , 'y' => 0.0 }
                    end
          
          # move left and bottom to zero, scale to fit and then center
          strokes.each do |stroke|
            stroke.each do |point|
              point['x'] = ((point['x'] - left) / long) + offset['x']
              point['y'] = ((point['y'] - bottom) / long) + offset['y']
            end
          end          
          
          # convert to equidistant point distributon
          strokes = strokes.map do |stroke|
            Detexify::Online::Preprocessors::EquidistantPoints.new(:distance => 0.01).process(stroke)            
          end
                    
          # FIXME I've lost the timestamps here. Dunno if I want to keep them
          
          extractors = []
          # extract features
          # - directional histogram features
          extractors << Detexify::Online::Extractors::DirectionalHistogramFeatures.new
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
          extractors << Detexify::Online::Extractors::PointDensity.new(*boxes)
          # - aspect ratio
          # - number of strokes
          extractors << Proc.new { |s| (s.size*10).to_f }
          # TODO add more features
          return Vector.elements(extractors.map { |e| e.call(strokes) }.flatten)
        end
        
      end
      
    end
    
    module ExtendedSymbol
      attr_reader :samples  
    end
    
    ### class Classifier
    
    K = 5
      
    # This is expensive
    # TODO load only { Vector => command } Hash (via CoucDB map)
    def samples
      @all ||= Sample.all.select { |sample| symbols.map { |symbol| symbol.id }.member? sample.symbol_id }
    end
    
    def symbols
      @symbols ||= Latex::Symbol::List # FIXME do I need @symbols?  
    end
    
    def symbol id
      Latex::Symbol[id]
    end
        
    def sample_counts
      h = {}
      symbols.each do |symbol|
        h[symbol.id] = 0
      end
      samples.each do |sample|
        h[sample.symbol_id] += 1
      end
      h
    end
        
    def count_samples symbol
      samples.select { |sample| sample.symbol_id == symbol.id }.size
    end
  
    # train the classifier
    def train id, io, strokes
      # TODO reject illegal input e.g. empty strokes
      # TODO offload feature extraction to a job queue
      f = extract_features io.read, strokes
      io.rewind
      begin
        sample = Sample.new(:symbol_id => id, :feature_vector => f, :strokes => strokes)
      rescue
        raise 'Panic!'
      end
      sample.save
      sample.put_attachment('source', io.read, :content_type => io.content_type)
      samples << sample
    end
  
    def classify io, strokes # TODO modules KNN, Mean, etc. for different classifier types? 
      f = extract_features io.read, strokes
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each command
      nearest = {}
      all = samples.sort_by do |sample|
        d = distance(f, Vector.elements(sample.feature_vector))
        nearest[sample.symbol_id] = d if !nearest[sample.symbol_id] || nearest[sample.symbol_id] > d
        d
      end
      neighbours = {} # holds nearest neighbours to pattern
      # K is number of best matches we want in the list
      while !all.empty? && neighbours.size < K
        sample = all.shift
        neighbours[sample.symbol_id] ||= 0
        neighbours[sample.symbol_id] += 1
      end
      # we are adding everything that is not in the nearest list with LARGE distance
      missing = symbols.map { |symbol| symbol.id } - nearest.keys
      # FIXME this feels slow
      return [neighbours.map { |id, num| { :symbol => Latex::Symbol[id].to_hash, :score => num } }.sort_by { |h| -h[:score] },
              nearest.map { |id, dist| { :symbol => Latex::Symbol[id].to_hash, :score => dist } }.sort_by{ |h| h[:score] } + missing.map { |id| { :symbol => Latex::Symbol[id].to_hash, :score => 999999} } ]
    end
    
    def distance x, y
      # TODO find a better distance function
      MyMath.euclidean_distance(x, y)
    end
    
    def regenerate_features
      puts "regenerating features"
      Sample.all.each do |s|
        f = extract_features(s.source, s.strokes)
        puts f.inspect
        s.feature_vector = f.to_a
        s.save
      end
      puts "done."
    end

    def extract_features data, strokes # data is String
      Features::Online.extract strokes # maybe use something different in the future
    end
        
  end
    
end