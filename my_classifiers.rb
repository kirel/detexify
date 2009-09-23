require 'classifiers'
require 'extractors'
require 'elastic_matcher'

include Classifiers

classifier :default do |cache|
  KnnClassifier.new(Detexify::Extractors::Strokes::Features.new, lambda { |v,w| (v-w).r }, :cache => cache)
end

classifier :elastic do
  Classifiers::DCPruningKnnClassifier.new(
    Detexify::Preprocessors::Pipe.new(
      Detexify::Preprocessors::Strokes::SizeNormalizer.new,
      Detexify::Preprocessors::Strokes::EquidistantPoints.new(:distance => 0.1)
    ),
    MultiElasticMatcher,
    [lambda { |i| i.size }, Detexify::Extractors::Strokes::AspectRatio.new(4)])
end