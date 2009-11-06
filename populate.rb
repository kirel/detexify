require 'mongo'
require 'restclient'
require 'json'
require 'base64'

include Mongo

samples = Connection.new.db('detexify').collection('samples')
progress = 0
percent = 0
count = samples.count

require 'benchmark'
Benchmark.bm do |bm|
  bm.report do
    
    samples.find.each do |s|
      data = JSON s['strokes']
      id = s['symbol_id']
      RestClient.post "localhost:3000/train/#{Base64.encode64(id)}", data
      progress += 1
      puts "#{percent = (progress*100.0/count).floor}% geladen" if (progress*100.0/count).floor > percent
    end
    
  end
end