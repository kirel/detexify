module Detexify
    
  class CappedContainer

    include Enumerable

    def initialize limit
      @limit = limit
      @hash = Hash.new { |h,v| h[v] = [] }
    end

    def << sample # wich is { :id => data }
      a = @hash[sample.id]
      a << sample
      a.shift if a.size > @limit    
      self
    end  

    def each &block
      @hash.each do |id, ary|
        ary.each do |sample|
          yield sample
        end
      end
    end

  end # CappedContainer

  Sample = Struct.new(:id, :data)
  
end