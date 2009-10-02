require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  #t.rcov = false
end

namespace :images do

  desc "create images from symbols.yaml"
  task :create do
    require 'storage'
    Latex::Storage::create_all
  end

end

namespace :features do

  desc "regenerate all feature vectors"
  task :regenerate do
    require 'app'
    CLASSIFIER.regenerate_features
  end

end

namespace :images do
  desc "remove images"
  task :delete do
    require 'couchrest'
    require 'sample'
    require 'symbol'
    Latex::Symbol::List.each do |symbol|
      sams = Detexify::Sample.by_symbol_id :key => symbol.id
      puts "working on #{symbol}"
      sams.each do |s|
        begin
          Detexify::Sample.database.delete_attachment(s, "source") if s.has_attachment? "source"
          print '.'
        rescue => e
          puts "\nError: #{e.inspect}\n"
        end
      end
    end
    puts 'done.'
  end
end