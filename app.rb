require 'uri'
require 'open-uri'
require 'data-uri'
require 'json'
require 'sinatra'
require 'detexify.rb' 

classifier = Detexify::Classifier.new

# mabye get '/symbol'

get '/symbols' do
  symbols = classifier.symbols.map { |s| s.to_hash }
  # update with counts
  sample_counts = classifier.sample_counts
  JSON symbols.map { |symbol| symbol.update(:samples => sample_counts[symbol[:id]]) }
end

post '/train' do
  halt 403, "Illegal id" unless params[:id] && classifier.symbol(params[:id])
  halt 403, 'I want some payload' unless params[:strokes] && params[:url]
  begin
    uri = URI.parse params[:url]
    unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
         raise "Only HTTP, FTP or Data!"
    end
    io = uri.open
  rescue
    halt 403, "Url scrambled"
  end
  begin
    strokes = JSON params[:strokes]
  rescue
    halt 403, "Strokes scrambled"
  end
  if strokes && !strokes.empty? && !strokes.first.empty?
    classifier.train params[:id], io, strokes
  else
    halt 403, "These strokes look suspicious"
  end
  # TODO sanity check in command list
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