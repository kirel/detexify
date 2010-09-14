require 'restclient'
require 'json'
require 'base64'
require 'armchair'
require 'classinatra/client'
require 'latex/symbol'
require 'threadify'
require 'stats'

require 'pp'

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

      # global stats
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
          rank = hits.index(id) + 1
          if rank
            stats.top! rank
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

        couch = CouchRest.database(ENV['COUCH'])
        testcouch = CouchRest.database(ENV['TESTCOUCH'])
        testcouch.recreate!
        traincouch = CouchRest.database(ENV['TRAINCOUCH'])
        traincouch.recreate!

        total_count = couch.view('tools/by_id', :reduce => true)['rows'].first['value']

        min_samples = 100 # only use classes with at least this many sampes
        max_samples = 75 # use max this many samples - should be at leas 3 ;)
        max_classes = 100 # use max this many classes

        timeleft = TimeLeft.new max_classes
        percent = 0.0

        classes_added = 0

        Latex::Symbol::List.each do |symbol|
          break if classes_added == max_classes

          count = couch.view('tools/by_id', :reduce => true, :key => symbol.to_sym.to_s)['rows'].first['value']

          if count > min_samples
            classes_added += 1
            res = couch.view('tools/by_id', :reduce => false, :limit => max_samples, :include_docs => true, :key => symbol.to_sym.to_s)
            docs = res['rows'][0, max_samples].map { |row| row['doc'] }

            puts '='*80
            puts "(#{classes_added}) Prodessing #{docs.size} samples of #{count} available for #{symbol}"

            border = docs.size/3
            test_docs = docs[0,border] # one third test
            train_docs = docs[border..-1] # two thirds training

            puts "Putting #{test_docs.size} samples into the test couch."
            testcouch.bulk_save(test_docs)
            puts "Putting #{train_docs.size} samples into the training couch."
            traincouch.bulk_save(train_docs)
            timeleft.done! 1
            puts "#{percent = (timeleft.done*100.0/max_classes).floor}% done (#{timeleft})" if (timeleft.done*100.0/max_classes).floor > percent
          end
        end # count.each

        puts "Done. Saved training and test data for #{classes_added} classes. #{timeleft.total} secs."
      end
    end
  end
end