require 'classifiers'
require 'extractors'
require 'elastic_matcher'

include Classifiers

classifier :default do |cache|
  KnnClassifier.new(Detexify::Extractors::Strokes::Features.new, lambda { |v,w| (v-w).r }, :cache => cache)
end

#CLASSIFIER = Classifiers::KnnClassifier.new(Detexify::Extractors::Strokes::Features.new, lambda { |v,w| (v-w).r }, :cache => CACHE)
#CLASSIFIER = Classifiers::DCPruningKnnClassifier.new(lambda{ |x| x }, MultiElasticMatcher, [lambda { |i| :all }])
#CLASSIFIER = Classifiers::DCPruningKnnClassifier.new(lambda{ |strokes| Detexify::Preprocessors::Strokes::SizeNormalizer.new.process strokes }, MultiElasticMatcher, [lambda { |i| i.size }])
