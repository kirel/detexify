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

# TODO url helper!

get '/' do
  # can i put this in a filter?
  unless params[:locale]
    if lang = request.env["HTTP_ACCEPT_LANGUAGE"]
      lang = lang.split(",").map do |l|
        l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
        l.split(';q=')
      end.first
      params[:locale] = lang.first.split("-").first
    else
      params[:locale] = i18n.default
    end
  end
  redirect "/#{params[:locale]}/classify"
end

get '/:locale/classify' do
  haml :classify
end

get '/:locale/train' do
  @tex = classifier.gimme_tex
  @samples = classifier.count_samples(@tex)
  haml :train
end

get '/:locale/symbols' do
  @tex = classifier.symbols
  @count = classifier.count_hash
  haml :symbols
end

post '/train' do
  halt 401, "I want tex!" unless params[:tex] && classifier.symbols.include?(params[:tex])
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
  # get new tex and build json response
  # TODO unless I don't want one
  if params[:newtex]
    tex = classifier.gimme_tex
    samples = classifier.count_samples(tex)
    JSON :tex => tex, :samples => samples
  end
end

post '/classify' do
  uri = URI.parse params[:url]
  strokes = JSON params[:strokes]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
    
  hits, all = classifier.classify io, strokes
  
  # sende { :url => url, :hits => [{:latex => latex, :score => score }, {:latex => latex, :score => score } ]  }
  JSON :url => params[:url], :hits => hits, :all => all
end