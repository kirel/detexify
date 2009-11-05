require 'json'
require 'sinatra'
require 'restclient'
require 'symbol'

# load DB
# require 'mongo'
# include Mongo

# samples = Connection.new.db('detexify').collection('samples')#('samples')
count = 0#samples.count
sample_counts = Hash.new { |h,k| h[k] = 0 }

# Thread.abort_on_exception = true
# Thread.new do
#   j=0
#   i=0
#   require 'benchmark'
#   Benchmark.bm do |bm|
#     bm.report do
#       samples.find.each do |s|
#         data = s['strokes'].map { |stroke| stroke.map { |point| Vector[point['x'], point['y']] }}
#         CLASSIFIER.train s['symbol_id'], data, s['_id']
#         sample_counts[s['symbol_id'].to_sym] += 1
#         i += 1
#         progress = (i*100)/count
#         if progress >= j
#           puts "#{progress}% geladen"
#           while j <= progress
#             j += 10
#           end
#         end
#       end        
#     end
#   end
#   loaded = true
# end

CLASSIFIER_URL = ENV['SERVICE'] || 'http://localhost:3000'

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
    # TODO save sample
    # sample_id = samples << { 'symbol_id' => params[:id], 'strokes' => strokes }
    # sample_counts[params[:id].to_sym] += 1
    
    rsp = RestClient.post CLASSIFIER_URL + "/train/#{params[:id]}", params[:strokes]
    halt 200, rsp
    
  else
    halt 403, "These strokes look suspicious"
  end
end

# classifies a set of strokes
# post param 'strokes' must be [['x':int x, 'y':int y, 't':int time], [...]]
post '/classify' do
  halt 401, 'I want some payload' unless params[:strokes]
  # strokes = JSON params[:strokes]
  rsp = RestClient.post CLASSIFIER_URL + "/classify", params[:strokes]
  hits = JSON rsp
  #, { :skip => params[:skip] && params[:skip].to_i, :limit => params[:limit] && params[:limit].to_i }
  nohits = Latex::Symbol::List - hits.map { |hit| Latex::Symbol[hit['id']] }
  hits = hits.map { |hit| { :symbol => Latex::Symbol[hit['id']].to_hash, :score => hit['score']} } + nohits.map { |symbol| { :symbol => symbol.to_hash, :score => 99999 } }
  JSON hits
end

# GUI

%w(/en/classify /de/classify).each do |path|
  get path do
    redirect '/classify.html'    
  end
end

get '/' do
  redirect '/classify.html'
end