require 'json'
require 'couchrest'
require 'classinatra/client'
require 'timeleft'

class PopulateTask < Rake::TaskLib

  def initialize name = :populate
    @name = name
    define
  end

  def define
    desc "Populate a CLASSIFIER with existing data from TRAINCOUCH."
    task @name do
      unless ENV['CLASSIFIER'] && ENV['TRAINCOUCH']
        abort "You must set CLASSIFIER and TRAINCOUCH environment variables!"
      end

      couch = CouchRest.database(ENV['TRAINCOUCH'])
      classifier = Classinatra::Client.at(ENV['CLASSIFIER'])

      # total_count = couch.view('tools/by_id', :reduce => true)['rows'].first['value']

      samples = 50

      timeleft = TimeLeft.new Latex::Symbol::List.size
      percent = 0.0

      Latex::Symbol::List.each do |symbol|

        res = couch.view('tools/by_id', :reduce => false, :limit => samples, :include_docs => true, :key => symbol.to_sym.to_s)
        docs = res['rows'].map { |row| row['doc'] }

        docs.each do |doc|
          next unless data = doc['data'] && doc['id']
          data = JSON(doc['data'])
          id = doc['id']
          tries = 0
          begin
            tries += 1
            r = classifier.train id, data
            print '*'
          rescue Net::HTTPError => e
            puts "Error: {e.message}"
            if tries < 4
              puts "retrying in #{tries**2} seconds"
              sleep tries**2
              retry
            end
          end
        end

        timeleft.done! 1
        puts
        puts "#{percent = (timeleft.done*100.0/Latex::Symbol::List.size).floor}% done (#{timeleft})" if (timeleft.done*100.0/Latex::Symbol::List.size).floor > percent
      end

      puts "Done. #{timeleft.total} secs."
    end
  end

end