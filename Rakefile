require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  t.rcov = true
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
    Detexify::Sample.all.each do |s|
      begin
        s.delete_attachment("source")
        s.save
      rescue => e
        puts "Error: #{e.inspect}"
      end
    end
    puts 'done.'
  end
end