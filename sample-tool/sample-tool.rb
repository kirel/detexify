require 'sinatra/base'
require "sinatra/reloader"
require "sinatra/json"
require 'sequel'
require 'json'

DB = Sequel.connect(ENV['POSTGRES_URL'] || ENV['DATABASE_URL'])

DB.extension(:pg_json)

class Sample < Sequel::Model
  plugin :json_serializer
end

class SampleTool < Sinatra::Base
  configure :development do
    register Sinatra::Reloader

    symbols_file = File.read('public/symbols.json')
    symbols = JSON.parse(symbols_file)
    set :symbols, symbols
  end

  get '/symbols' do
    counts = Sample.group_and_count(:key).map{|r| {r[:key] => r[:count]} }.reduce(&:merge)
    json settings.symbols.map { |s| s.merge(sample_count: counts[s['id'].to_s] || 0) }
  end

  get '/samples' do
    json count: Sample.count
  end

  get '/samples/:key' do
    json Sample.where(key: params[:key])
  end

  post '/samples/:key' do
    not_found unless settings.symbols.find { |s| s["id"] == params[:key] }
    strokes = params[:strokes].map { |stroke| stroke.map { |point| point.values_at("x", "y", "t") } }
    Sample.create(key: params[:key], strokes: Sequel.pg_json(strokes))
    200
  end

  delete '/samples/:id' do
    Sample.where(id: params[:id]).delete
    200
  end

  run! if app_file == $0
end
