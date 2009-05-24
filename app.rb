require 'uri'
require 'open-uri'
require 'data-uri'
require 'json'
require 'sinatra'

load 'detexify.rb' 

MATHTRANURL = 'http://www.mathtran.org/cgi-bin/mathtran?D=%s;tex=%s'

Classifier = Detexify::Classifier.new # database_url

get '/' do
  haml :classify
end

get '/train' do
  @tex = open('commands.txt') do |f|
    cmds = f.readlines
    cmds[rand cmds.size]
  end
  
  haml :train
end

post '/train' do
  uri = URI.parse params[:url]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  Classifier.train params[:tex], io
  halt 200
end

get '/js/jquery' do
  send_file 'js/jquery-1.3.2.min.js'
end

%w(mathtran canvassify classify train).each do |js|
  get "/js/#{js}" do
    send_file "js/#{js}.js"
  end  
end

get '/image' do
  # open(MATHTRANURL % [params[:"D"] || 1.to_s, params[:tex] || "foo"].map { |p| URI::escape(p) }) do |f|
  #     content_type f.content_type || 'application/octet-stream'
  #     last_modified f.last_modified
  #     response['Content-Length'] = f.size
  #     halt f
  #   end
  redirect MATHTRANURL % [params[:"D"] || 1.to_s, params[:tex] || "foo"].map { |p| URI::escape(p) }
end

get '/classify' do
  uri = URI.parse params[:url]
  unless [URI::HTTP, URI::FTP, URI::Data].any? { |c| uri.is_a? c }
       halt 401, "Only HTTP, FTP or Data!"
  end
  io = uri.open
  
  # hits = nil
  # open('commands.txt') do |f|
  #   hits = f.readlines.map { |t| {:tex => t, :score => 'drölf' } } 
  # end
  
  hits = Classifier.classify io
  
  # sende { :url => url, :hits => [{:latex => latex, :score => score }, {:latex => latex, :score => score } ]  }
  JSON :url => params[:url], :hits => hits
end