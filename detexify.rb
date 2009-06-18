require 'couchrest'
require 'extended_enumerable'
require 'matrix'
require 'math'
require 'preprocessors'
require 'extractors'
require 'image_moments'
require 'RMagick'

module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    dburl = ENV['COUCH'] || "http://127.0.0.1:5984/samples"
    use_database CouchRest.database!(dburl)
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
        
        def extract s
          strokes = s.map { |stroke| stroke.map { |point| point.dup } } # s.dup enough?
          # preprocess strokes
          
          # TODO chop off heads and tails
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Chop.new(:points => 5, :degree => 180).process(stroke)            
          # end

          # TODO smooth out points (avarage over three points)
          # strokes = strokes.map do |stroke|
          #   Preprocessors::Smooth.new.process(stroke)            
          # end
                    
          left, right, top, bottom = Detexify::Online::Extractors::BoundingBox.new.extract(strokes)
          
          # TODO push this into a preprocessor
          # computations for next step
          height = top - bottom
          width = right - left
          ratio = width/height
          long, short = ratio > 1 ? [width, height] : [height, width]
          offset =  if ratio > 1
                      { 'x' => 0.0 , 'y' => (1.0 - short/long)/2.0 }
                    else
                      { 'x' => (1.0 - short/long)/2.0 , 'y' => 0.0 }
                    end
          
          # move left and bottom to zero, scale to fit and then center
          strokes.each do |stroke|
            stroke.each do |point|
              point['x'] = ((point['x'] - left) / long) + offset['x']
              point['y'] = ((point['y'] - bottom) / long) + offset['y']
            end
          end          
          
          # convert to equidistant point distributon
          strokes = strokes.map do |stroke|
            Detexify::Online::Preprocessors::EquidistantPoints.new(:distance => 0.01).process(stroke)            
          end
                    
          # FIXME I've lost the timestamps here. Dunno if I want to keep them
          
          # extract features
          # - directional histogram features
          n, ne, e, se, s, sw, w, nw = Detexify::Online::Extractors::DirectionalHistogramFeatures.new.extract(strokes)
          # - start direction
          # - end direction
          # startdirection, enddirection = Extractors::StartEndDirection.new.process(strokes)
          # - start/end position
          # - point density
          # - aspect ratio
          # - number of strokes
          
          # TODO add more features
          Vector[n, ne, e, se, s, sw, w, nw, strokes.size]
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
    
    def symbols
      cmds, more = open('commands.txt') do |f|
        f.readlines
      end.reject do |c|
        c =~ /\A#/
      end.map do
        |c| c.strip
      end.partition do |c|
        c !~ /\{\}/
      end
      more.each do |command|
        (('a'..'z').to_a+('A'..'Z').to_a).each do |char|
          cmds << command.sub(/\{\}/,"{#{char}}") 
        end
      end
      cmds
    end
    
    def gimme_tex
      # TODO refoactor so that it is prettier
      reload # FIXME this is slow!
      cmds = symbols
      cmdh = {}
      cmds.each do |cmd|
        cmdh[cmd] = 0
      end
      @all.each do |sample|
        if cmdh[sample.command]
          cmdh[sample.command] += 1
        else
          puts "****** Hilfe! Fremdes Symbol: #{sample.command}"
        end
      end
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
      k = 5 # number of best matches we want in the list
      while !all.empty? && neighbours.size < k
        sample = all.shift
        neighbours[sample.command] ||= 0
        neighbours[sample.command] += 1
      end
      neighbours.map { |command, num| { :tex => command, :score => num } }.sort_by { |h| -h[:score] }
    end
    
    def distance x, y
      # TODO find a better distance function
      MyMath.euclidean_distance(x, y)
    end
    
    def regenerate_features
      puts "regenerating features"
      # FIXME see extended_enumerable.rb
      #@samples.each do |s|
      @samples.all.each do |s|
        f = extract_features(s.source, s.strokes)
        puts f.inspect
        s.feature_vector = f.to_a
        s.save
      end
      puts "done."
    end

    protected

    def extract_features data, strokes # data is String
      Features::Online.extract strokes # maybe use something different in the future
    end
        
  end
    
end