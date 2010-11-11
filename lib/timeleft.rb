class TimeLeft

  def initialize num
    @all = num
    @start = Time.now
    @done = 0
  end

  attr_reader :start, :finish, :done

  def done! num = 1
    @done += num.to_i
    if @done >= @all
      @finish = Time.now
    end
  end

  def left
    [@all - @done, 0].max
  end

  def per
    per = ((@finish || Time.now) - @start)/@done
  end

  # seconds left
  def to_f
    per = (Time.now - @start)/@done
    per * left
  end

  def to_i
    self.to_f.to_i
  end

  # time when probably done
  def to_time
    @finish || Time.now + self.to_f
  end

  def to_s
    "#{self.to_i} seconds left"
  end

  def done?
    !!@finish
  end

  def total
    if done?
      @finish - @start
    else
      self.to_time - @start
    end
  end

end
