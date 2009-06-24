require 'uri'
require 'open-uri'
require 'data-uri'
require 'json'
require 'sinatra'
require 'sinatra/r18n'
require 'haml'

load 'detexify.rb' 

classifier = Detexify::Classifier.new

enable :sessions

before do
  if params[:locale]
    session[:locale] = params[:locale]
  end
  unless session[:locale]
    session[:locale] = request.env["HTTP_ACCEPT_LANGUAGE"][0,2]
  end
end

get '/locale' do
  session[:locale]
end

get '/i18n' do
  out = ''
  out << i18n.inspect
  out << i18n.translations.inspect
end

get '/' do
  haml :classify
end

get '/train' do
  @tex = classifier.gimme_tex
  @samples = classifier.count_samples(@tex)
  haml :train
end

get '/symbols' do
  @tex = classifier.symbols
  @count = classifier.count_hash
  haml :symbols
end

post '/train' do
  halt 401, "I want tex!" unless params[:tex]
  uri = URI.parse params[:url]
  strokes = JSON params[:strokes]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  
  # TODO sanity check in command list
  if strokes && !strokes.empty? && !strokes.first.empty?
    classifier.train params[:tex], io, strokes # if symbols.contain? params[:tex]
  end
  # halt 200 if xhr else
  redirect '/train'
end

post '/classify' do
  uri = URI.parse params[:url]
  strokes = JSON params[:strokes]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
    
  hits = classifier.classify io, strokes
  
  # sende { :url => url, :hits => [{:latex => latex, :score => score }, {:latex => latex, :score => score } ]  }
  JSON :url => params[:url], :hits => hits
end