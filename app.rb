require 'uri'
require 'open-uri'
require 'data-uri'
require 'json'
require 'sinatra'

load 'detexify.rb' 

classifier = Detexify::Classifier.new # database_url

get '/' do
  haml :classify
end

get '/train' do
  @tex = open('commands.txt') do |f|
    cmds = f.readlines
    cmds[rand(cmds.size)]
  end
  
  haml :train
end

post '/train' do
  # TODO sanity check in command list
  uri = URI.parse params[:url]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  
  classifier.train params[:tex], io
  halt 200
end

post '/classify' do
  uri = URI.parse params[:url]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  
  # hits = nil
  # open('commands.txt') do |f|
  #   hits = f.readlines.map { |t| {:tex => t, :score => 'drölf' } } 
  # end
  
  hits = classifier.classify io
  
  # sende { :url => url, :hits => [{:latex => latex, :score => score }, {:latex => latex, :score => score } ]  }
  JSON :url => params[:url], :hits => hits
end

get '/image' do
  # open(MATHTRANURL % [params[:"D"] || 1.to_s, params[:tex] || "foo"].map { |p| URI::escape(p) }) do |f|
  #     content_type f.content_type || 'application/octet-stream'
  #     last_modified f.last_modified
  #     response['Content-Length'] = f.size
  #     halt f
  #   end
  redirect 'http://www.mathtran.org/cgi-bin/mathtran?D=%s;tex=%s' % [params[:"D"] || 1.to_s, params[:tex] || "foo"].map { |p| URI::escape(p) }
end
