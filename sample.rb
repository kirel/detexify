module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    DB = ENV['COUCH'] || "http://127.0.0.1:5984/detexify"
    use_database CouchRest.database!(DB)
    property :feature_vector
    property :strokes
    
    timestamps!
                          
    def source
      fetch_attachment 'source'
    end
    
    def ===(other)
      self.rev === other.rev && self.id === other.id
    end
    
  end

end