require 'sinatra/base'
require "sinatra/reloader"
require "sinatra/json"
require 'sequel'
require 'json'

DB = Sequel.connect(ENV['POSTGRES_URL'])

DB.extension(:pg_json)

class Sample < Sequel::Model
  plugin :json_serializer
end

class SampleTool < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/symbols' do
    symbols_file = File.read('public/symbols.json')
    symbols = JSON.parse(symbols_file)
    counts = Sample.group_and_count(:key).map{|r| {r[:key] => r[:count]} }.reduce(&:merge)
    json symbols.map { |s| s.merge(sample_count: counts[s['id'].to_s] || 0) }
  end

  get '/samples' do
    json count: Sample.count
  end

  get '/samples/:key' do
    json Sample.where(key: params[:key])
  end

  delete '/samples/:id' do
    Sample.where(id: params[:id]).delete
    200
  end

  run! if app_file == $0
end
