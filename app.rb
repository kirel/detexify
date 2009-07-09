require 'uri'
require 'open-uri'
require 'data-uri'
require 'json'
require 'sinatra'

load 'detexify.rb' 

classifier = Detexify::Classifier.new

# mabye get '/symbol'

get '/symbols' do
  symbols = classifier.symbols.map { |s| s.to_hash }
  # update with counts
  sample_counts = classifier.sample_counts
  JSON symbols.map { |symbol| symbol.update(:samples => sample_counts[symbol[:id]]) }
end

post '/train' do
  halt 401, "Illegal id" unless params[:id] && classifier.symbol(params[:id])
  halt 401, 'I want some payload' unless params[:strokes] && params[:url]
  uri = URI.parse params[:url]
  strokes = JSON params[:strokes]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  
  # TODO sanity check in command list
  if strokes && !strokes.empty? && !strokes.first.empty?
    classifier.train params[:id], io, strokes
  end
  halt 200
  # TODO return new list of symbols and counts
end

post '/classify' do
  halt 401, 'I want some payload' unless params[:strokes] && params[:url]
  strokes = JSON params[:strokes]
  uri = URI.parse params[:url]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
    halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  best, all = classifier.classify io, strokes  
  JSON :best => best, :all => all
end