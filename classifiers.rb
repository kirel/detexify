require 'sample'
require 'decision_tree' # TODO autoload

module Classifiers

  Hit = Struct.new :id, :score
    
  # classifiers

  class KnnClassifier
        
    K = 5
    SAMPLE_LIMIT = 50

    def initialize extractor, measure, options = {}
      @extractor = extractor
      @measure = measure
      @samples = CappedContainer.new SAMPLE_LIMIT # TODO add to options
      @cache = options[:cache]
      @semaphore = Mutex.new # synchronize access to @samples
    end
    
    # train the classifier
    def train id, data, sample_id = nil # _id is for caching purposes
      extracted = if @cache && sample_id
                    @cache.fetch(sample_id.to_s) { @extractor.call(data) }
                  else
                    @extractor.call(data)
                  end
      synchronize do
        @samples << Sample.new(id, extracted)
      end
    end

    def classify data, options = {}
      unknown = @extractor.call(data)
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each class
      minimal_distance_hash = {}
      sorted = synchronize do
        # puts @samples.size
        # i = 0
        @samples.sort_by do |sample|
          # puts "**** Vergleiche"
          d = @measure.call(unknown, sample.data)
          minimal_distance_hash[sample.id] = d if (!minimal_distance_hash[sample.id]) || (minimal_distance_hash[sample.id] > d)
          # puts "Abstand #{d}"
          # if d.nan?
          #   puts "-Unbekannt- #{unknown.inspect}"
          #   puts "-Muster- #{sample.inspect}"
          # end
          # puts (i += 1)
          d
        end
      end
      neighbours = Hash.new { |h,v| h[v] = 0 } # counting classes of neighbours
      # K is number of best matches we want in the list
      while (!sorted.empty?) && (neighbours.size < K)
        sample = sorted.shift # next nearest sample to f
        neighbours[sample.id] += 1 # counting neighbours of that class
      end
      max_nearest_neighbours_distance = neighbours.map { |id, _| minimal_distance_hash[id] }.max
      # TODO explain
      computed_neighbour_distance = {}
      neighbours.each { |id, num| computed_neighbour_distance[id] = max_nearest_neighbours_distance.to_f/num }
      minimal_distance_hash.update(computed_neighbour_distance)
      # FIXME this feels slow
      ret = minimal_distance_hash.map { |id, dist| Hit.new id, dist }.sort_by{ |h| h.score }
      # limit and skip
      ret = ret[options[:skip] || 0, options[:limit] || ret.size] if [:limit, :skip].any? { |k| options[k] }
      return ret
    end
    
    protected
    
    def synchronize &block
      @semaphore.synchronize &block
    end

  end # KnnClassifier
  
  class DCPruningKnnClassifier < KnnClassifier
        
    def initialize extractor, measure, deciders, options = {}
      @extractor = extractor
      @measure = measure
      @tree = DecisionTree.new deciders
      @semaphore = Mutex.new
    end
    
    def train id, data, sample_id = nil
      synchronize do
        @tree << Sample.new(id, @extractor.call(data), sample_id.to_s)
      end
    end
    
    def classify data, options = {}
      synchronize do
        @samples = @tree.call data
      end
      super data, options
    end
    
  end
  
  @@classifier_blueprints = {}
  
  module_function
  
  def classifier key, &block
    @@classifier_blueprints[key] = proc &block
  end
  
  def [] key, cache = nil
    @@classifier_blueprints[key].call cache
  end
  

end