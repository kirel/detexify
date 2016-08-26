require 'sequel'
require 'set'
require './lib/latex/symbol'
require 'pry'

DB = Sequel.connect(ENV['POSTGRES_URL'])

DB.extension(:pg_json)

class Sample < Sequel::Model
  plugin :json_serializer
end

set = Set.new
to_delete = []

puts "#{Sample.count} samples in db"

Sample.paged_each do |sample|
  if not set.add? sample.strokes.flatten.reduce(:+)
    puts "#{sample.id} in #{sample.key} is a duplicate"
    to_delete << sample
  elsif sample.strokes.count > 10
    puts "#{sample.id} in #{sample.key} has #{sample.strokes.count}>10 strokes"
    to_delete << sample
  elsif (num_points = sample.strokes.map(&:count).reduce(:+)) > 1000
    puts "#{sample.id} in #{sample.key} has #{num_points}>1000 points"
    to_delete << sample
  end
end

to_delete.each(&:delete)

puts "#{Sample.count} samples in db"
