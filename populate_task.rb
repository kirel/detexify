require 'restclient'
require 'json'
require 'base64'
require 'couch'
require 'actionpool'

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
      pool = ActionPool::Pool.new :min_threads => 3, :max_threads => 10
      couch.each do |doc|
        data = JSON(doc['data'])
        id = doc['id']
        pool.process do
          RestClient.post "#{cla}/train/#{Base64.encode64(id)}", data
          puts "#{percent = (progress*100.0/count).floor}% geladen" if ((progress+=1)*100.0/count).floor > percent
        end
      end
      puts "done. #{(Time.now.to_i-start)} secs."
    end
  end

end