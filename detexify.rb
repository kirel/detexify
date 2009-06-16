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
    property :strokes
    
    timestamps!
                          
    def source
      fetch_attachment 'source'
    end
    
  end

  class Classifier
    
    module Features
      
      module Hu
        extend ImageMoments
        
        module_function
        
        def extract data
          h = img2hu(data2img(data))
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
      
      # extract online fetures
      module Online
        
        module_function
        
        def extract strokes
          # normalize strokes
          # extract features
          # - directional histogram features
          # - start direction?
          # - end direction?
          # - aspect ratio
          Vector[] # TODO
        end
        
        def normalize strokes
          # TODO smooth out points
          # TODO chop heads and tails
          # TODO maximally fit into [0,1]x[0,1]
          # TODO convert to equidistant point distribution 0.1
          strokes
        end
        
      end
      
    end
    
    ### class Classifier
  
    def initialize
      @samples = Sample
      @all = @samples.all
    end
    
    def reload
      @all = @samples.all
    end
    
    def gimme_tex
      # TODO refoactor so that it is prettier
      cmds = open('commands.txt') { |f| f.readlines }
      cmdh = {}
      cmds.each do |cmd|
        cmdh[cmd.strip] = 0
      end
      p cmdh
      @all.each do |sample|
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
      reload
    end
  
    # returns [{ :command => "foo", :score => "100", }]
    def classify io, strokes # TODO modules KNN, Mean, etc. for different classifier types? 
      f = extract_features io.read, strokes
      # use nearest neighbour classification
      all = @all.sort_by { |sample| distance(f, Vector.elements(sample.feature_vector)) }
      neighbours = {}
      k = 3 # number of best matches we want in the list
      while !all.empty? && neighbours.size < k
        sample = all.shift
        neighbours[sample.command] ||= 0
        neighbours[sample.command] += 1
      end
      neighbours.map { |command, num| { :tex => command, :score => num } }.sort_by { |h| -h[:score] }
    end
    
    def distance x, y
      # TODO find a better distance function
      Statistics.euclidean_distance(x, y)
    end
    
    def regenerate_features
      puts "regenerating features"
      # FIXME see extended_enumerable.rb
      #@samples.each do |s|
      @samples.all.each do |s|
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