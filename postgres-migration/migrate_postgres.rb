require 'sequel'
require 'oj'

DB = Sequel.connect(ENV['POSTGRES_URL'])

DB.extension(:pg_json)

puts "Creating DB"

DB.create_table! :samples do
  primary_key :id
  String :key
  index :key
  json :strokes
end

puts "Loading JSON"

samples = DB[:samples]
json = Oj.load_file('detexify.json', mode: :strict, bigdecimal_load: :float) do |obj|
   next if obj['strokes'].empty?
   samples.insert({
     key: obj['key'],
     strokes: Sequel.pg_json(obj['strokes'])
   })
   STDOUT.print('.')
end

puts "done."
