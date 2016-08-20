require 'sinatra/base'
require "sinatra/reloader"
require "sinatra/json"
require 'sequel'
require '../lib/latex/symbol'

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
    counts = Sample.group_and_count(:key).map{|r| {r[:key] => r[:count]} }.reduce(&:merge)
    json Latex::Symbol::List.map { |s| s.to_hash.merge(sample_count: counts[s.id.to_s] || 0) }
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
