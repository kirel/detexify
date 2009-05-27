require 'couchrest'
require 'extended_enumerable'
require 'matrix'
require 'statistics'
require 'image_moments'
require 'rmagick'

module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    use_database CouchRest.new.database! 'samples' # FIXME database?
    property :command
    property :feature_vector
    
    timestamps!
    
    view_by :mean,
      :map => open(File.join(File.expand_path(File.dirname(__FILE__)), 'js/mean-map.js')).read,
      :reduce => open(File.join(File.expand_path(File.dirname(__FILE__)), 'js/mean-reduce.js')).read
    
    # TODO view_by :covariance_matrix
            
    def source
      read_attachment 'source'
    end
      
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
    
    module Features
      
      module Hu
        extend ImageMoments
        
        module_function
        
        def extract data
          img2hu(data2img(data))
        end
        
        def data2img data
          img = Magick::Image::from_blob(data).first
          puts img.inspect
          puts "-"*80
          puts "got image"
          puts "  Format: #{img.format}"
          puts "  Geometry: #{img.columns}x#{img.rows}"
          puts "  Depth: #{img.depth} bits-per-pixel"
          puts "  Colors: #{img.number_colors}"
          puts "  Filesize: #{img.filesize}"
          puts "-"*80
          img
        end

        def img2hu img
          puts "-"*80
          puts "computing hu moments"
          # FIXME next statement uses opacity which is VERY STRANGE but it only works that way
          a = (0..(img.rows-1)).collect { |n| img.get_pixels(0,n,img.columns,1).collect { |p| p.opacity } }
          m = Matrix[*a]
          puts "panic!!!!!! zero matrix" if m == Matrix.zero(m.column_size)
          h = hu_vector(m, 0..(m.column_size-1), 0..(m.row_size-1) )
          puts "hu moments"
          puts "  #{h.inspect}"
          puts "-"*80
          h
        end
        
      end
      
    end
      
  
    def initialize database_url = 'http://127.0.0.1:5984'
      @db = CouchRest.new(database_url).database! 'samples'
      @samples = Sample#.on(@db) # FIXME
    end
  
    # train the classifier by adding io to symbol class tex
    def train tex, io
      # TODO offload feature extraction to a job queue
      f = extract_features io.read
      io.rewind
      sample = @samples.new(:command => tex, :feature_vector => f.to_a)
      sample.create_attachment(:name => 'source', :file => io, :content_type => io.content_type)
      sample.save
    end
  
    # returns [{ :command => "foo", :score => "100", }]
    def classify io
      f = extract_features io.read
      ms = @samples.means
      # TODO use mahalanobis distance for commands with enough samples -> m[:count]
      ms.map { |m| { :tex => m[:command], :score => Statistics.euclidean_distance(f, m[:mean]) } }.sort_by { |h| h[:score] }
    end
    
    def regenerate_features
      puts "regenerating features"
      @samples.each do |s|
        data = s.source
        f = extract_features(data)
        s.feature_vector = f.to_a
        s.save
      end
      puts
      puts "done."
    end

    protected

    def extract_features data # String
      # TODO use a fast C Library
      Features::Hu.extract data # maybe use something different in the future
    end
        
  end
    
end