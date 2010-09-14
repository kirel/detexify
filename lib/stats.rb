class Stats

  def initialize
    @tests = 0
    @top = [0]*10
  end

  attr_reader :tests

  def top x
    @top[x-1]
  end

  def percentage_top x
    top(x)*100.0/tests
  end

  def top! x
    @tests += 1
    x.upto(10).each do |i|
      @top[i-1] += 1
    end
  end

  def failed!
    @tests += 1
  end

end

if $0 == __FILE__
  require 'test/unit'

  class TestStats < Test::Unit::TestCase
    def test_stats
      @t = Stats.new
      @t.top! 10
      assert_equal 1, @t.top(10)
      assert_equal 1, @t.tests
      @t.top! 1
      (1..9).each { |i|  assert_equal @t.top(i), 1 }
      assert_equal 2, @t.top(10)
      assert_equal 2, @t.tests
    end
  end
end