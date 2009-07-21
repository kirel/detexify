module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    property :feature_vector
    property :strokes
    property :symbol_id
    
    view_by :symbol_id
    
    #timestamps!
    
    def symbol
      Latex::Symbol[symbol_id]
    end
    
  end
  
  # These will stay in memory all the time
  class MiniSample
    
    attr_reader :feature_vector, :symbol_id
    
    def initialize sample
      @feature_vector = sample.feature_vector
      @symbol_id = sample.symbol_id.to_sym # to_sym so only one instance of the string exists
    end
    
  end
  
  class Samples
    
    include Enumerable
    
    def initialize
      @minisamples = []
    end
    
    def each &block
      @minisamples.each &block
    end
    
    def << sample
      @minisamples << MiniSample.new(sample)
      self
    end
    
  end

end