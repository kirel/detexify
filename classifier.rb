require 'couchrest'
require 'matrix'
require 'math'
require 'preprocessors'
require 'extractors'
require 'symbol'
require 'sample'

module Detexify
    
  class Classifier
                
    K = 5
    
    def initialize stroke_extractor, data_extractor
      @stroke_extractor, @data_extractor = stroke_extractor, data_extractor
    end
      
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
      h = Hash.new { |h,v| h[v] = 0 }
      samples.each do |sample|
        h[sample.symbol_id] += 1
      end
      h
    end
        
    def count_samples symbol
      samples.select { |sample| sample.symbol_id == symbol.id }.size
    end
  
    # train the classifier
    def train id, strokes, io
      # TODO reject illegal input e.g. empty strokes
      # TODO offload feature extraction to a job queue
      f = extract_features io.read, strokes
      io.rewind
      sample = Sample.new(:symbol_id => id, :feature_vector => f, :strokes => strokes)
      sample.save
      sample.put_attachment('source', io.read, :content_type => io.content_type)
      samples << sample
    end
  
    def classify strokes, io # TODO modules KNN, Mean, etc. for different classifier types? 
      f = extract_features io.read, strokes
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each command
      nearest = {}
      all = samples.sort_by do |sample|
        # FIXME catch exception Dimension mismatch here
        d = distance(Vector.elements(f), Vector.elements(sample.feature_vector))
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
        s.feature_vector = f
        s.save
      end
      puts "done."
    end

    def extract_features data, strokes # data is String
      features = []
      features << @stroke_extractor.call(strokes) if @stroke_extractor
      features << @data_extractor.call(data) if @data_extractor
      features.flatten
    end
        
  end
    
end