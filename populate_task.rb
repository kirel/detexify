require 'restclient'
require 'json'
require 'base64'
require 'couch'
require 'puddle'

class PopulateTask < Rake::TaskLib
  
  def initialize name = :populate
    @name = name
    define
  end
  
  def define
    desc "Populate a CLASSIFIER with existing data from COUCH."
    task @name do
      unless ENV['CLASSIFIER'] && ENV['COUCH']
        abort "You must set CLASSIFIER and COUCH environment variables!"
      end
      
      cla = ENV['CLASSIFIER'].sub(/\/?$/,'')
      couch = Couch.new(ENV['COUCH'].sub(/\/?$/,'/'))
      couch.create!
      
      count = couch.size.to_f
      progress = 0.0
      percent = 0.0

      start = Time.now.to_i
      pool = Puddle.new
      couch.each do |doc|
        pool.process do
          data = JSON(doc['data'])
          id = doc['id']
          tries = 0
          begin
            tries += 1
            RestClient.post "#{cla}/train/#{Base64.encode64(id)}", data
          rescue RestClient::Exception => e
            puts "Error: {e.message}"
            if tries < 4
              puts "retrying in #{tries**2} seconds"
              sleep tries**2
              retry
            end
          end
          progress += 1
          puts "#{percent = (progress*100.0/count).floor}% geladen" if (progress*100.0/count).floor > percent
        end
      end # count.each
      puts "done. #{(Time.now.to_i-start)} secs."
      pool.drain
    end
  end

end