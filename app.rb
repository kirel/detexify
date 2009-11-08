require 'json'
require 'sinatra'
require 'restclient'
require 'symbol'
require 'base64'
require 'couch'

classifier = (ENV['CLASSIFIER'] || 'http://localhost:3000').sub(/\/?$/,'')
couch = Couch.new((ENV['COUCH'] || 'http://localhost:5984/detexify').sub(/\/?$/,'/'))
couch.create!

sample_counts = Hash.new { |h,k| h[k] = 0 } # TODO sample counts

get '/symbols' do
  symbols = Latex::Symbol::List.map { |s| s.to_hash }
  # update with counts
  JSON Latex::Symbol::List.map { |s| s.to_hash.update :samples => sample_counts[s.id.to_sym] }
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
    rsp = RestClient.post classifier + "/train/#{Base64.encode64(params[:id])}", params[:strokes]
    couch << {'id' => params[:id], 'data' => strokes }
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
  rsp = RestClient.post classifier + "/classify", params[:strokes]
  hits = JSON rsp
  #, { :skip => params[:skip] && params[:skip].to_i, :limit => params[:limit] && params[:limit].to_i }
  nohits = Latex::Symbol::List - hits.map { |hit| Latex::Symbol[Base64.decode64(hit['id'])] }
  hits = hits.map { |hit| { :symbol => Latex::Symbol[Base64.decode64(hit['id'])].to_hash, :score => hit['score']} } + nohits.map { |symbol| { :symbol => symbol.to_hash, :score => 99999 } }
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