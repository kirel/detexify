require 'json'
require 'sinatra'
require 'matrix'
require 'symbol'
require 'couch'
require 'memcache'

require 'my_classifiers'

CACHE = MemCache.new('localhost:11211')
CLASSIFIER = Classifiers[:default, CACHE]

# load DB

require 'mongo'
include Mongo

samples = Connection.new.db('detexify').collection('samples')#('samples')

i=0
require 'benchmark'
Benchmark.bm do |bm|
  bm.report do
samples.find.each do |s|
  data = s['strokes'].map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
  data.extend(Module.new do |mod|
    mod.send :define_method, :_id do
      s['_id']
    end
  end)
  CLASSIFIER.train s['symbol_id'], data
  i += 1
end
  end
end

puts i

@loaded = true, @progress = 100 # TODO
@sample_counts = Hash.new { |h,k| h[k] = 0 }
# TODO load the data

get '/status' do
  JSON :loaded => true, :progress => 100
end

get '/symbols' do
  symbols = Latex::Symbol::List.map { |s| s.to_hash }
  # update with counts
  JSON symbols.map { |symbol| symbol.update(:samples => 0) }#@sample_counts[symbol[:id]]) }
end

post '/train' do
  halt 403, "Illegal id" unless params[:id] && Latex::Symbol[params[:id].to_sym]
  halt 403, 'I want some payload' unless params[:strokes]
  begin
    strokes = JSON params[:strokes]
  rescue
    halt 403, "Strokes scrambled"
  end
  if strokes && !strokes.empty? && !strokes.first.empty?
    # begin
      s = strokes.map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
      CLASSIFIER.train params[:id], s
    # rescue Detexify::Classifier::TooManySamples
    #   # FIXME can I handle http status codes in the request? Wanna go restful
    #   #halt 403, "Thanks - i've got enough of these..."
    #   halt 200, JSON(:error => "Thanks but I've got enough of these...")
    # end
    
    # TODO update sample counts
    
    # *** TODO also persist 
    # samples << strokes
  else
    halt 403, "These strokes look suspicious"
  end
  # TODO sanity check in command list
  halt 200, JSON(:message => "Symbol was successfully trained.")
  # TODO return new list of symbols and counts
end

# classifies a set of strokes
# post param 'strokes' must be [['x':int x, 'y':int y, 't':int time], [...]]
post '/classify' do
  halt 401, 'I want some payload' unless params[:strokes]
  strokes = JSON params[:strokes]
  s = strokes.map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
  hits = CLASSIFIER.classify s#, { :skip => params[:skip] && params[:skip].to_i, :limit => params[:limit] && params[:limit].to_i }
  JSON hits.map { |hit| { :symbol => Latex::Symbol[hit.id].to_hash, :score => hit.score} }
end