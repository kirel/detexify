require 'json'
require 'sinatra/base'

module Detexify

  # settings.symbols needs to respond to #[] and each
  # a symbol needs to respond to #to_sym and #to_json
  # settings.couch needs to respond to #<<
  # settings.classifier is a classifier #train #classify #stats
  class Base < Sinatra::Base 
    
    get '/symbols' do
      @rsp ||= JSON(settings.symbols.map {|s|{:id => s.to_sym, :symbol => s, :samples => samples[s.to_sym]}})
    end

    post '/train' do
      id = validate_id
      strokes = validate_strokes
      rsp = settings.classifier.train id, JSON(strokes)
      settings.couch << {'id' => id, 'data' => strokes } rescue puts "Saving to couch failed"
      samples[id] += 1
      # response
      content_type 'application/json'
      status 200
      JSON(rsp)
    end

    post '/classify' do
      strokes = validate_strokes
      rawhits = settings.classifier.classify JSON(strokes)
      nohits = syms - rawhits.map { |hit| hit[:id].to_sym }
      hits = rawhits.map do |hit|
        symbol = settings.symbols[hit[:id].to_sym]
        hit.merge(:symbol => symbol) if symbol
      end.compact + nohits.map { |sym| {:id => sym, :symbol => settings.symbols[sym], :score => 99999 } }
      if params[:skip] || params[:limit]
        skip =  params[:skip].to_i.to_s == params[:skip] && params[:skip].to_i || 0 
        limit = params[:limit].to_i.to_s == params[:limit] && params[:limit].to_i || hits.size
        hits = hits[skip,limit]
      end
      # response
      content_type 'application/json'
      status 200
      JSON(hits)
    end

    # GUI

    get '/' do
      redirect '/classify.html'
    end

    protected
    
    def e(message)
      content_type 'application/json'
      halt 400, JSON(:error => message)
    end

    def validate_id
      e("Illegal id") unless params[:id] && syms.include?(params[:id].to_sym)
      params[:id].to_sym
    end

    # post param 'strokes' must be [['x':int x, 'y':int y, 't':int time], [...]]
    def validate_strokes
      begin
        e('Illegal strokes') unless
          params[:strokes] &&
          strokes = JSON(params[:strokes]) #&&
          #          !strokes.empty? &&
          #          !strokes.first.empty?
          # TODO more thorough checks
      rescue
        e('Illegal strokes')
      end
      strokes
    end

    def syms
      @symcache ||= Set.new(settings.symbols.map { |s| s.to_sym })
    end

    def samples
      unless @counts_cache
        @counts_cache = Hash.new { |h,k| h[k] = 0 } # TODO sample counts
        settings.classifier.stats[:counts].each do |id, c|
          @counts_cache[id.to_sym] += c
        end 
      end
      @counts_cache
    end

  end # Detexify::Base
  
end