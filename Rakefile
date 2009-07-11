require 'spec/rake/spectask'
require 'app'
require 'storage'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  t.rcov = true
end

namespace :images do

  desc "create images from symbols.yaml"
  task :create do
    Latex::Storage::create_all
  end

end

namespace :features do

  desc "regenerate all feature vectors"
  task :regenerate do
    CLASSIFIER.regenerate_features
  end

end