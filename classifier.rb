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
    SAMPLE_LIMIT = 500
    
    # returns load status in percent
    attr_reader :progress
    
    def loaded?
      progress == 100
    end

    def initialize stroke_extractor, data_extractor
      @stroke_extractor, @data_extractor = stroke_extractor, data_extractor
      @progress = 0
      load_samples
    end

    def samples
      @samples# || load_samples
    end

    def symbols
      @symbols ||= Latex::Symbol::List # FIXME do I need @symbols?  
    end

    def symbol id
      Latex::Symbol[id]
    end

    attr_reader :sample_counts

    def count_samples symbol
      if symbol.respond_to? :to_sym
        @sample_counts[symbol.to_sym]
      else # should be a symbol
        @sample_counts[symbol.id]
      end
    end

    # errors for use with train an classify
    IllegalSymbolId = Class.new(ArgumentError)
    DataMessedUp = Class.new(ArgumentError)
    TooManySamples = Class.new(RuntimeError)

    # train the classifier
    def train id, strokes, io
      raise IllegalSymbolId unless Latex::Symbol[id]
      raise DataMessedUp unless data_ok?(strokes, io)
      raise TooManySamples if count_samples(id) >= SAMPLE_LIMIT
      # TODO offload feature extraction to a job queue
      f = extract_features io.read, strokes
      io.rewind
      sample = Sample.new(:symbol_id => id, :feature_vector => f, :strokes => strokes)
      sample.save
      sample.put_attachment('source', io.read, :content_type => io.content_type) # TODO abstract!
      samples << sample
      @sample_counts[id.to_sym] += 1
    end

    def classify strokes, io # TODO modules KNN, Mean, etc. for different classifier types? 
      raise DataMessedUp unless data_ok?(strokes, io)
      f = extract_features io.read, strokes
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each command
      nearest = {}
      all = samples.sort_by do |sample|
        # FIXME catch exception Dimension mismatch here
        d = distance(Vector.elements(f), Vector.elements(sample.feature_vector))
        nearest[sample.symbol_id] = d if (!nearest[sample.symbol_id]) || (nearest[sample.symbol_id] > d)
        d
      end
      neighbours = Hash.new { |h,v| h[v] = 0 } # holds nearest neighbours to pattern
      # K is number of best matches we want in the list
      while (!all.empty?) && (neighbours.size < K)
        sample = all.shift # next nearest sample to f
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
      # TODO do this by symbol
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
    
    def wait_until_loaded
      @load_thread.join
    end

    private
    
    def data_ok? strokes, io
      # TODO more and better checks
      strokes.is_a?(Array) && io.respond_to?(:read) && io.respond_to?(:content_type)
    end

    def load_samples
      @samples = Samples.new
      @sample_counts = Hash.new { |h,k| h[k] = 0 }
      # load by symbol in a new thread
      @load_thread = Thread.new do
        symbols.each_with_index do |symbol,i|
          # TODO allow more concurrent requests or load in batches
          samples = Sample.by_symbol_id(:key => symbol.id)
          @samples << samples
          @sample_counts[symbol.id] += samples.size
          @progress = 100*(i+1)/symbols.size
        end
      end
      @samples
    end

  end

end