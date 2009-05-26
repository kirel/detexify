require 'delegate'

module CouchRest  
  class Document < Response
    include CouchRest::Mixins::Attachments

    # def self.inherited(subklass)
    #   subklass.send(:extlib_inheritable_accessor, :database)
    # end
    
    extlib_inheritable_accessor :database
    attr_accessor :database
    
    # override the CouchRest::Model-wide default_database
    # This is not a thread safe operation, do not change the model
    # database at runtime.
    def self.use_database(db)
      self.database = db
    end
    
    def id
      self['_id']
    end
    
    def rev
      self['_rev']
    end
    
    # returns true if the document has never been saved
    def new_document?
      !rev
    end
    
    # Saves the document to the db using create or update. Also runs the :save
    # callbacks. Sets the <tt>_id</tt> and <tt>_rev</tt> fields based on
    # CouchDB's response.
    # If <tt>bulk</tt> is <tt>true</tt> (defaults to false) the document is cached for bulk save.
    def save(bulk = false)
      raise ArgumentError, "doc.database required for saving" unless database
      result = database.save_doc self, bulk
      result['ok']
    end

    # Deletes the document from the database. Runs the :delete callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    # If <tt>bulk</tt> is <tt>true</tt> (defaults to false) the document won't 
    # actually be deleted from the db until bulk save.
    def destroy(bulk = false)
      raise ArgumentError, "doc.database required to destroy" unless database
      result = database.delete_doc(self, bulk)
      if result['ok']
        self['_rev'] = nil
        self['_id'] = nil
      end
      result['ok']
    end
    
    # copies the document to a new id. If the destination id currently exists, a rev must be provided.
    # <tt>dest</tt> can take one of two forms if overwriting: "id_to_overwrite?rev=revision" or the actual doc
    # hash with a '_rev' key
    def copy(dest)
      raise ArgumentError, "doc.database required to copy" unless database
      result = database.copy_doc(self, dest)
      result['ok']
    end
    
    # Returns the CouchDB uri for the document
    def uri(append_rev = false)
      return nil if new_document?
      couch_uri = "http://#{database.uri}/#{CGI.escape(id)}"
      if append_rev == true
        couch_uri << "?rev=#{rev}"
      elsif append_rev.kind_of?(Integer)
        couch_uri << "?rev=#{append_rev}"
      end
      couch_uri
    end
    
    # Returns the document's database
    def database
      @database || self.class.database
    end
    
  end
  
end
