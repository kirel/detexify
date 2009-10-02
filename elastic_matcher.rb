# coding:utf-8

# can be used as a measure between two strokes (arrays of vectors)
# TODO sets of strokes

require 'matrix'

# ElasticMatcher = lambda do |first, second|
#   
# end

module Enumerable
  def sum(*args, &block)
    if block_given?
      map &block
    else
      self
    end.inject(*args) { |sum, x| sum + x }
  end
end

class ElasticMatcher
  
  def call first, second
    reset first.size
    D first, second
  end
  
  private

  def reset num
    @distance_memory = Hash.new { |h,v| h[v] = {} }
    @dynamic_memory = Array.new(num) { [] }
  end

  def d point, qoint # two vectors
    @distance_memory[point][qoint] ||= (point - qoint).r
  end

  def D r,s
    n, m = r.size-1, s.size-1
    if n == 0 # r is only one point left
      # need to map remaining points of s to remaining point in s
      return(s.sum { |e| d(e, r.first) })
    end
    if m == 0 # s is only 1 point left
      # need to map remaining points of s to remaining point in r
      return(r.sum { |e| d(e, s.first) })
    end
    @dynamic_memory[n][m] ||= d(r[n],s[m]) + [ 
      D(r, s[0..-2]),
      D(r[0..-2], s),
      D(r[0..-2], s[0..-2])
    ].min
  end  
end

MultiElasticMatcher = lambda do |first, second|
  @matcher = ElasticMatcher.new
  small, long = first.size < second.size ? [first, second] : [second, first]
  res = (0...small.size).sum { |i| @matcher.call(small[i], long[i]) }
  # if long is longer match all remaining against last stroke of small
  res += (small.size...long.size).sum { |i| @matcher.call(small.last, long[i]) } || 0
end

if __FILE__ == $0
  require 'test/unit'
  
  class TestElasticMatcher < Test::Unit::TestCase
    
    def setup
      @matcher = ElasticMatcher.new
    end
    
    def test_match_self_exactly
      s,t = [(1..10).map { Vector[rand, rand] }]*2
      assert_equal(@matcher.call(s,t), 0)
    end
    
    def test_does_not_match_different
      s,t = [[Vector[0,0]],[Vector[0,1]]]
      assert_not_equal(@matcher.call(s,t), 0)
    end
  end
  
end