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
    
    def == other
      @symbol_id == other.symbol_id && @feature_vector == other.feature_vector
    end
    
  end
  
  class MiniSampleContainer
    
    include Enumerable
    
    def initialize limit
      @limit = limit
      @hash = Hash.new { |h,v| h[v] = [] }
    end
    
    def << sample
      sample =  MiniSample.new(sample) unless sample.is_a? MiniSample
      a = @hash[sample.symbol_id]
      a << sample
      a.shift if a.size > @limit
      self
    end  
      
    def each &block
      @hash.each do |id, a|
        a.each do |sample|
          yield sample
        end
      end
    end
    
    def for_id id
      @hash[id]
    end
    
  end
  
end