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
    end
    
    # train the classifier
    def train id, data
      extracted = if @cache
                    @cache.fetch(data._id.to_s) { @extractor.call(data) }
                  else
                    @extractor.call(data)
                  end
      @samples << Sample.new(id, extracted)
    end

    def classify data, options = {}
      unknown = @extractor.call(data)
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each class
      minimal_distance_hash = {}
      sorted = @samples.sort_by do |sample|
        d = @measure.call(unknown, sample.data)
        minimal_distance_hash[sample.id] = d if (!minimal_distance_hash[sample.id]) || (minimal_distance_hash[sample.id] > d)
        d
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

  end # KnnClassifier
  
  class DCPruningKnnClassifier < KnnClassifier
        
    def initialize extractor, measure, deciders, options = {}
      @extractor = extractor
      @measure = measure
      @tree = DecisionTree.new deciders
    end
    
    def train id, data
      @tree << Sample.new(id, @extractor.call(data))
    end
    
    def classify data, options = {}
      @samples = @tree.call data
      super data, options
    end
    
  end

end