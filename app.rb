require 'json'
require 'sinatra'
require 'matrix'
require 'symbol'
# require 'couch'
require 'memcache'

require 'my_classifiers'

CACHE = MemCache.new('localhost:11211')
CLASSIFIER = Classifiers[:default, CACHE]
#CLASSIFIER = Classifiers[:dcelastic, CACHE]

# load DB
require 'mongo'
include Mongo

samples = Connection.new.db('detexify').collection('samples')#('samples')
count = samples.count
loaded, progress = false, 0
sample_counts = Hash.new { |h,k| h[k] = 0 }

Thread.abort_on_exception = true
Thread.new do
  j=0
  i=0
  require 'benchmark'
  Benchmark.bm do |bm|
    bm.report do
      samples.find.each do |s|
        data = s['strokes'].map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
        CLASSIFIER.train s['symbol_id'], data, s['_id']
        sample_counts[s['symbol_id'].to_sym] += 1
        i += 1
        progress = (i*100)/count
        if progress >= j
          puts "#{progress}% geladen"
          while j <= progress
            j += 10
          end
        end
      end        
    end
  end
  loaded = true
end

get '/status' do
  JSON :loaded => loaded, :progress => progress
end

get '/symbols' do
  symbols = Latex::Symbol::List.map { |s| s.to_hash }
  # update with counts
  JSON Latex::Symbol::List.map { |s| s.to_hash.update :samples => sample_counts[s.id.to_sym] }#@sample_counts[symbol[:id]]) }
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
    sample_id = samples << { 'symbol_id' => params[:id], 'strokes' => strokes }
    s = strokes.map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
    CLASSIFIER.train params[:id].to_sym, s, sample_id
    sample_counts[params[:id].to_sym] += 1
    # rescue Detexify::Classifier::TooManySamples
    #   # FIXME can I handle http status codes in the request? Wanna go restful
    #   #halt 403, "Thanks - i've got enough of these..."
    #   halt 200, JSON(:error => "Thanks but I've got enough of these...")
    # end
    
    # TODO update sample counts
    
    # *** TODO also persist 
    
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
  hits = CLASSIFIER.classify s
  #, { :skip => params[:skip] && params[:skip].to_i, :limit => params[:limit] && params[:limit].to_i }
  JSON hits.map { |hit| { :symbol => Latex::Symbol[hit.id].to_hash, :score => hit.score} }
end