require 'couchrest'
require 'extended_enumerable'
require 'matrix'
require 'statistics'
require 'image_moments'
require 'RMagick'

module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    dburl = ENV['COUCH'] || "http://127.0.0.1:5984/samples"
    use_database CouchRest.database! dburl
    property :command
    property :feature_vector
    
    timestamps!
    
    view_by :mean,
      :map => open(File.join(File.expand_path(File.dirname(__FILE__)), 'js/command-vector-map.js')).read,
      :reduce => open(File.join(File.expand_path(File.dirname(__FILE__)), 'js/mean-reduce.js')).read
          
    # TODO view_by :covariance_matrix
            
    def source
      fetch_attachment 'source'
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
      
  
    def initialize# database_url = 'http://127.0.0.1:5984'
      #@db = CouchRest.new(database_url).database! 'samples'
      @samples = Sample#.on(@db) # FIXME
    end
    
    def gimme_tex
      cmds = open('commands.txt') { |f| f.readlines }
      all = @samples.all
      cmdh = {}
      cmds.each do |cmd|
        cmdh[cmd.strip] = 0
      end
      p cmdh
      all.each do |sample|
        puts sample.command
        cmdh[sample.command] += 1
      end
      p cmdh
      cmdh.sort_by { |c,n| n }.first.first
    end
  
    # train the classifier by adding io to symbol class tex
    def train tex, io, strokes
      # TODO offload feature extraction to a job queue
      f = extract_features io.read, strokes
      io.rewind
      sample = @samples.new(:command => tex, :feature_vector => f.to_a, :strokes => strokes)
      sample.save
      sample.put_attachment('source', io.read, :content_type => io.content_type)
    end
  
    # returns [{ :command => "foo", :score => "100", }]
    def classify io, strokes
      f = extract_features io.read, strokes
      # use nearest neighbour classification
      # TODO Store everything in memory instead of getting it from the DB all the time
      # @all ||= @samples.all.map do |sample|
      all = @samples.all.sort_by { |sample| Statistics.euclidean_distance(f, Vector.elements(sample.feature_vector)) }
      neighbours = {}
      k = 10
      while !all.empty? && neighbours.size <= k
        sample = all.shift
        neighbours[sample.command] ||= 0
        neighbours[sample.command] += 1
      end
      neighbours.map { |command, num| { :tex => command, :score => num } }.sort_by { |h| -h[:score] }
    end
    
    def regenerate_features
      puts "regenerating features"
      @samples.each do |s|
        f = extract_features(s.source, s.strokes)
        s.feature_vector = f.to_a
        s.save
      end
      puts
      puts "done."
    end

    protected

    def extract_features data, strokes # data is String
      Features::Hu.extract data # maybe use something different in the future
    end
        
  end
    
end