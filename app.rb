require 'json'
require 'sinatra'
require 'classifiers'
require 'extractors'
require 'matrix'
require 'symbol'

#COUCH = ENV['COUCH'] || "http://127.0.0.1:5984/detexify"

CLASSIFIER = Classifiers::KnnClassifier.new(Detexify::Extractors::Strokes::Features.new, lambda { |v,w| (v-w).r })

configure do
end
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
  JSON hits
end