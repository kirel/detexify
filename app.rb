require 'json'
require 'sinatra'
require 'classifier.rb' 

COUCH = ENV['COUCH'] || "http://127.0.0.1:5984/detexify"
CLASSIFIER = Detexify::Classifier.new(COUCH, Detexify::Extractors::Strokes::Features.new)

%w(/en/classify /de/classify).each do |path|
  get path do
    redirect '/classify.html'    
  end
end

get '/' do
  redirect '/classify.html'
end

get '/status' do
  JSON :loaded => CLASSIFIER.loaded?, :progress => CLASSIFIER.progress
end

get '/symbols' do
  symbols = CLASSIFIER.symbols.map { |s| s.to_hash }
  # update with counts
  sample_counts = CLASSIFIER.sample_counts
  JSON symbols.map { |symbol| symbol.update(:samples => sample_counts[symbol[:id]]) }
end

post '/train' do
  halt 403, "Illegal id" unless params[:id] && CLASSIFIER.symbol(params[:id])
  halt 403, 'I want some payload' unless params[:strokes]
  begin
    strokes = JSON params[:strokes]
  rescue
    halt 403, "Strokes scrambled"
  end
  if strokes && !strokes.empty? && !strokes.first.empty?
    begin
      CLASSIFIER.train params[:id], strokes
    rescue Detexify::Classifier::TooManySamples
      # FIXME can I handle http status codes in the request? Wanna go restful
      #halt 403, "Thanks - i've got enough of these..."
      halt 200, JSON(:error => "Thanks but I've got enough of these...")
    end
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
  hits = CLASSIFIER.classify strokes
  JSON hits
end