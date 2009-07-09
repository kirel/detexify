module Detexify
    
  class Sample < CouchRest::ExtendedDocument
    DB = ENV['COUCH'] || "http://127.0.0.1:5984/detexify"
    use_database CouchRest.database!(DB)
    property :feature_vector
    property :strokes
    property :symbol_id
    
    #timestamps!
                          
    def source
      fetch_attachment 'source'
    end
    
    def symbol
      Latex::Symbol[symbol_id]
    end
        
  end

end