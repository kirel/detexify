BASEDIR = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'couchrest'
require 'matrix'
require 'statistics'

module Detexify

  # TODO
  # module CouchRest
  #   module Mixins

  module EnumerableDocument
    DEFAULT_BATCHSIZE = 25

    def self.included(base)
      base.class_eval do
        view_by :_id
      end
      base.extend ClassMethods
      base.extend Enumerable
    end

    module ClassMethods
      def batch(num = DEFAULT_BATCHSIZE, opts = {}, &block)
        b = self.all(opts.merge!(:limit => num+1))
        while b.size == num+1
          this_batch, start = b[0..-2], b[-1]
          yield this_batch
          b = self.by__id(opts.merge!(:limit => num+1, :startkey => start.id))
        end
        yield b
      end

      def each(&block)
        self.batch do |b|
          b.each do |s|
            yield s
          end
        end
      end
    end
  end
    
  class Sample < CouchRest::ExtendedDocument
    use_database CouchRest.new.database! 'samples' # FIXME database?
    property :command
    property :feature_vector
    
    timestamps!
    
    view_by :mean,
      :map => open(File.join(BASEDIR, 'js/mean-map.js')).read,
      :reduce => open(File.join(BASEDIR, 'js/mean-reduce.js')).read
      
    include EnumerableDocument # TODO CouchRest::ExtendedDocument.send :include ExtendedEnumerable
      
    def source
      read_attachment 'source'
    end
      
    # TODO view_by :covariance_matrix

    def Sample.mean command
      result = by_mean :key => command, :group => true, :reduce => true
      Vector.elements result['rows'][0]['value']['mean']
    end
    
    def Sample.means
      result = by_mean :group => true, :reduce => true
      m = {}
      result['rows'].map do |row|
        {
          :command => row['key'],
          :mean => Vector.elements(row['value']['mean']),
          :count => row['value']['count']
        }
      end
    end
    
  end

  class Classifier
  
    def initialize database_url = 'http://127.0.0.1:5984'
      @db = CouchRest.new(database_url).database! 'samples'
      @samples = Sample#.on(@db)
    end
  
    # train the classifier by adding io to symbol class tex
    def train tex, io
      f = extract_features io.read
      sample = @samples.new(:command => tex, :feature_vector => f.to_a)
      sample.create_attachment(:name => 'source', :file => io, :content_type => io.content_type )
      sample.save
    end
  
    # returns [{ :command => "foo", :score => "100", }]
    def classify io
      f = extract_features io.read
      ms = @samples.means
      puts "************ #{ms.inspect}"
      # TODO use mahalanobis distance for commands with enough samples -> m[:count]
      ms.map { |m| { :tex => m[:command], :score => Statistics.euclidean_distance(Vector.elements(f), m[:mean]) } }.sort_by { |h| -h[:score] }
    end
    
    def regenerate
      @samples.each do |s|
        data = s.source
        s.feature_vector = extract_features data
      end
    end

    protected

    def extract_features data # String
      # TODO 
      return [1,1,1,1] # bogus
    end
    
  end
    
end