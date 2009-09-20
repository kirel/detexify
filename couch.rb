module Couch
  
  require 'couchrest'
  require 'symbol'
  
  class Sample < CouchRest::ExtendedDocument
    use_database CouchRest.database!("http://127.0.0.1:5984/detexify-samples")
    
    property :feature_vector
    property :strokes
    property :symbol_id
    
    view_by :symbol_id
    
    #timestamps!
    
    def symbol
      Latex::Symbol[symbol_id]
    end
    
  end
  
end