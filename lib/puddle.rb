require 'thread'

# Something like a thread pool but without a queue
class Puddle
  def initialize num = 10
    @num = num
    @threads = []
  end
  
  # blocks until it can pass the block to a new thread (a lock is open)
  def process
    tries = 0
    loop do
      if @threads.size < @num
        break
      else
        sleep(tries+=1)
      end
    end
    @threads << t = Thread.start do
      yield
      @threads.delete(Thread.current)
    end
    t
  end
  
  def drain
    @threads.dup.map { |t| t.join }
  end
end