require 'yaml'
require 'digest'

module Latex

  class Symbol
        
    #:nodoc:
    A = [:command, :package, :fontenc, :mathmode, :textmode]
    
    attr_reader(*A)
    attr_reader :id

    def initialize args = {}
      raise ArgumentError.new('You need at least a command for a LaTeX symbol.') unless args[:command]
      # defauls
      args = { :textmode => true, :mathmode => false }.update(args)
      # init
      args.each do |k,v|
        instance_variable_set "@#{k}", v if A.include? k
      end
      @id = "#{package || 'latex2e'}-#{fontenc || 'OT1'}-#{command.gsub('\\','_')}".to_sym
    end
    
    def [](k)
      send k if A.include?(k) || k == :id
    end
    
    # def ==(other)
    #   id == other.id
    # end
    
    def to_s
      "#{command} (#{package || 'latex2e'}, #{fontenc || 'OT1'})"
    end
    
    def to_sym
      @id.to_sym
    end
    
    def filename
      # id.to_s
      'symbol' + Digest::MD5.hexdigest(id.to_s)
    end
    alias css_class filename
    
    def uri
      "http://detexify.kirelabs.org.s3.amazonaws.com/images/latex/#{filename}.png"
    end
    
    def to_hash
      h = {}
      A.each { |a| !self[a].nil? && (h[a] = self[a]) }
      h[:id] = self[:id]
      h[:uri] = uri
      h[:css_class] = css_class
      h
    end
    
    def to_json(*a)
      to_hash.to_json(*a)
    end
    
    symbols = File.open( File.join(File.expand_path(File.dirname(__FILE__)),'symbols.yaml') ) { |f| YAML::load( f ) }

    List = symbols.map do |s|
      case s
      when String
        new(:command => s)
      when Hash
        { 
          'textmode' => { :textmode => true, :mathmode => false},
          'mathmode' => { :textmode => false, :mathmode => true},
          'bothmodes' => { :textmode => true, :mathmode => true}
        }.map do |mode, modeargs|
          if s[mode]
            s[mode].map do |t|
              new({:command => t, :package => s['package'], :fontenc => s['fontenc']}.merge!(modeargs))
            end
          end   
        end.compact # remove nil elements    
      end
    end.flatten
    
    ExtendedList = List.inject({}) { |h,s| h.update(s.to_sym => s) }
    
    def ExtendedList.each
      super do |k,v|
        yield v
      end
    end
    
    def self.[](id)
      id = id.to_sym
      List.find { |symbol| symbol.id == id }
    end
            
  end
end
