require 'restclient'
require 'json'
require 'base64'
require 'armchair'
require 'classinatra/client'

class BenchmarkTask < Rake::TaskLib
  
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
  
  def initialize name = :populate
    @name = name
    define
  end
  
  def define
    desc "Test CLASSIFIER with data from TESTCOUCH. Requires population first."
    task :benchmark do
      unless ENV['CLASSIFIER'] && ENV['TESTCOUCH']
        abort "You must set CLASSIFIER and TESTCOUCH environment variables!"
      end

      cla = Classinatra::Client.at(ENV['CLASSIFIER'])
      couch = Armchair.new(ENV['TESTCOUCH'])

      count = couch.size
      timeleft = TimeLeft.new count
      percent = 0.0

      # THE ALLMIGHTY STATS
      stats = Stats.new
      per_symbol_stats = Hash.new { |h,k| h[k] = Stats.new }

      couch.each do |doc|
        data = JSON(doc['data'])
        id = doc['id']
        tries = 0
        begin
          tries += 1
          res = cla.classify data
          hits = res.sort_by {|r| r[:score] }.map { |r| r[:id] }
          rank = hits.index(id)
          if rank
            stats.top! rank + 1 
            per_symbol_stats[id].top! rank
          else
            stats.failed!
            per_symbol_stats[id].failed!
          end
        rescue RestClient::Exception => e
          puts "Error: #{e.message}"
          if tries < 4
            puts "retrying in #{tries**2} seconds"
            sleep tries**2
            retry
          end
        rescue StandardError => e
          puts "Error: #{e.class} #{e.message}"
          puts "probably an error in the server occurred. sorry."
          puts data
          puts id
          puts res
        end
        timeleft.done! 1
        puts "#{percent = (timeleft.done*100.0/count).floor}% getestet (#{timeleft})" if (timeleft.done*100.0/count).floor > percent
      end # count.each
      puts "done. #{timeleft.total} secs."
      puts 'Per symbol stats:'
      per_symbol_stats.sort_by { |id, st| st.top(1) }.each do |id, st|
        puts "- #{Latex::Symbol[id]} - #{st.tests} Tests"
        1.upto(10) do |p|
          # note we have 3 test-symbols
          puts "Top #{p}: #{st.percentage_top(p)}%"
        end
      end
      puts 'Flop 10:'
      per_symbol_stats.dup.sort_by { |id, st| st.top(10) }[0,10].each do |id, st|
        puts "#{Latex::Symbol[id]} - #{st.percentage_top(10)}% top 10"
      end
      puts 'Top 10:'
      per_symbol_stats.dup.sort_by { |id, st| -st.top(10) }[0,10].each do |id, st|
        puts "#{Latex::Symbol[id]} - #{st.percentage_top(10)}% top 10"
      end
      puts 'Global stats:'
      1.upto(10) do |p|
        puts "Top #{p}: #{stats.percentage_top(p)}%"
      end
      puts "Overall #{stats.tests} Tests for #{per_symbol_stats.size} Symbols in #{timeleft.total} secs needing #{timeleft.per} secs per test."
    end
    
    namespace :benchmark do
      desc "Prepare TESTCOUCH and TRAINCOUCH from COUCH as... testcouch and benchcouch..."
      task :prepare do
        unless ENV['COUCH'] && ENV['TESTCOUCH'] && ENV['TRAINCOUCH']
          abort "You must set COUCH, TESTCOUCH and TRAINCOUCH environment variables!"
        end

        couch = Armchair.new(ENV['COUCH'])
        testcouch = Armchair.new(ENV['TESTCOUCH'])
        traincouch = Armchair.new(ENV['TRAINCOUCH'])
        testcouch.create!
        traincouch.create!

        count = couch.size
        timeleft = TimeLeft.new count
        percent = 0.0

        ### read all the docs
        docs = {}
        max = 9
        min = 3
        classes = 30
        couch.each do |doc|
          next unless doc['id'] && doc['data']
          docs[doc['id']] ||= []
          docs[doc['id']] << doc if docs[doc['id']].size <= max
          timeleft.done! 1
          puts "#{percent = (timeleft.done*100.0/count).floor}% read (#{timeleft})" if (timeleft.done*100.0/count).floor > percent
        end # count.each
        puts "reading done. #{timeleft.total} secs."
        puts 'About to distribute...'

        ### shrink
        docs.delete_if { |_,d| d.size < min }
        docs.delete(docs.keys.first) while docs.size > classes

        ### distribute
        
        count = docs.size
        timeleft = TimeLeft.new count
        percent = 0.0

        docs.each do |_,d|
          distribute = d.shuffle
          distribute[0..(distribute.size/3)].each { |doc| testcouch << doc }
          distribute[((distribute.size/3)+1)..(-1)].each { |doc| traincouch << doc }

          timeleft.done! 1
          puts "#{percent = (timeleft.done*100.0/count).floor}% written (#{timeleft})" if (timeleft.done*100.0/count).floor > percent
        end

        puts "Distribution done. #{timeleft.total} secs."

      end
    end
  end
end