# Helper to migrate data from mongodb back to the couch
#
require 'json'
require 'restclient'
require 'mongo'
include Mongo
mongo = Connection.new.db('detexify').collection('samples')
couch = ENV['COUCH'] || 'http://localhost:5984/detexify/'
RestClient.get couch rescue RestClient.put couch, nil
c = mongo.count.to_f
i = 0.0
p = -1.0
mongo.find.each do |doc|
  RestClient.post couch, JSON('id' => doc['symbol_id'], 'data' => doc['strokes'])
  i += 1.0
  puts "#{p = (i/c*100).floor} %" if (i/c*100).floor > p 
end
puts 'done.'