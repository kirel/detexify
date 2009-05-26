require 'detexify'

namespace :features do

  desc "regenerate all feature vectors"
  task :regenerate do
    c = Detexify::Classifier.new
    c.regenerate_features
  end
  
end