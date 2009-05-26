require 'mime/types'
require File.join(File.dirname(__FILE__), "property")
require File.join(File.dirname(__FILE__), '..', 'mixins', 'extended_document_mixins')

module CouchRest
  
  # Same as CouchRest::Document but with properties and validations
  class ExtendedDocument < Document
    include CouchRest::Callbacks
    include CouchRest::Mixins::DocumentQueries    
    include CouchRest::Mixins::Views
    include CouchRest::Mixins::DesignDoc
    include CouchRest::Mixins::ExtendedAttachments
    include CouchRest::Mixins::ClassProxy
    
    def self.inherited(subklass)
      subklass.send(:include, CouchRest::Mixins::Properties)
      subklass.class_eval <<-EOS, __FILE__, __LINE__
        def self.inherited(subklass)
          subklass.properties = self.properties.dup
        end
      EOS
    end
    
    # Accessors
    attr_accessor :casted_by
    
    # Callbacks
    define_callbacks :create
    define_callbacks :save
    define_callbacks :update
    define_callbacks :destroy
    
    def initialize(passed_keys={})
      apply_defaults # defined in CouchRest::Mixins::Properties
      passed_keys.each do |k,v|
        if self.respond_to?("#{k}=")
          self.send("#{k}=", passed_keys.delete(k))
        end
      end if passed_keys
      super
      cast_keys      # defined in CouchRest::Mixins::Properties
      unless self['_id'] && self['_rev']
        self['couchrest-type'] = self.class.to_s
      end
    end
    
    
    # Automatically set <tt>updated_at</tt> and <tt>created_at</tt> fields
    # on the document whenever saving occurs. CouchRest uses a pretty
    # decent time format by default. See Time#to_json
    def self.timestamps!
      class_eval <<-EOS, __FILE__, __LINE__
        property(:updated_at, :read_only => true, :cast_as => 'Time', :auto_validation => false)
        property(:created_at, :read_only => true, :cast_as => 'Time', :auto_validation => false)
        
        save_callback :before do |object|
          object['updated_at'] = Time.now
          object['created_at'] = object['updated_at'] if object.new_document?
        end
      EOS
    end
  
    # Name a method that will be called before the document is first saved,
    # which returns a string to be used for the document's <tt>_id</tt>.
    # Because CouchDB enforces a constraint that each id must be unique,
    # this can be used to enforce eg: uniq usernames. Note that this id
    # must be globally unique across all document types which share a
    # database, so if you'd like to scope uniqueness to this class, you
    # should use the class name as part of the unique id.
    def self.unique_id method = nil, &block
      if method
        define_method :set_unique_id do
          self['_id'] ||= self.send(method)
        end
      elsif block
        define_method :set_unique_id do
          uniqid = block.call(self)
          raise ArgumentError, "unique_id block must not return nil" if uniqid.nil?
          self['_id'] ||= uniqid
        end
      end
    end
    
    # Temp solution to make the view_by methods available
    def self.method_missing(m, *args, &block)
      if has_view?(m)
        query = args.shift || {}
        view(m, query, *args, &block)
      else
        super
      end
    end
    
    ### instance methods
    
    # Returns the Class properties
    #
    # ==== Returns
    # Array:: the list of properties for the instance
    def properties
      self.class.properties
    end
    
    # Takes a hash as argument, and applies the values by using writer methods
    # for each key. It doesn't save the document at the end. Raises a NoMethodError if the corresponding methods are
    # missing. In case of error, no attributes are changed.    
    def update_attributes_without_saving(hash)
      hash.each do |k, v|
        raise NoMethodError, "#{k}= method not available, use property :#{k}" unless self.respond_to?("#{k}=")
      end      
      hash.each do |k, v|
        self.send("#{k}=",v)
      end
    end

    # Takes a hash as argument, and applies the values by using writer methods
    # for each key. Raises a NoMethodError if the corresponding methods are
    # missing. In case of error, no attributes are changed.
    def update_attributes(hash)
      update_attributes_without_saving hash
      save
    end

    # for compatibility with old-school frameworks
    alias :new_record? :new_document?
    
    # Trigger the callbacks (before, after, around)
    # and create the document
    # It's important to have a create callback since you can't check if a document
    # was new after you saved it
    #
    # When creating a document, both the create and the save callbacks will be triggered.
    def create(bulk = false)
      caught = catch(:halt)  do
        _run_create_callbacks do
            _run_save_callbacks do
              create_without_callbacks(bulk)
          end
        end
      end
    end
    
    # unlike save, create returns the newly created document
    def create_without_callbacks(bulk =false)
      raise ArgumentError, "a document requires a database to be created to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new_document? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      (result["ok"] == true) ? self : false
    end
    
    # Creates the document in the db. Raises an exception
    # if the document is not created properly.
    def create!
      raise "#{self.inspect} failed to save" unless self.create
    end
    
    # Trigger the callbacks (before, after, around)
    # only if the document isn't new
    def update(bulk = false)
      caught = catch(:halt)  do
        if self.new_document?
          save(bulk)
        else
          _run_update_callbacks do
            _run_save_callbacks do
              save_without_callbacks(bulk)
            end
          end
        end
      end
    end
    
    # Trigger the callbacks (before, after, around)
    # and save the document
    def save(bulk = false)
      caught = catch(:halt)  do
        if self.new_document?
          _run_save_callbacks do
            save_without_callbacks(bulk)
          end
        else
          update(bulk)
        end
      end
    end
    
    # Overridden to set the unique ID.
    # Returns a boolean value
    def save_without_callbacks(bulk = false)
      raise ArgumentError, "a document requires a database to be saved to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new_document? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      result["ok"] == true
    end
    
    # Saves the document to the db using save. Raises an exception
    # if the document is not saved properly.
    def save!
      raise "#{self.inspect} failed to save" unless self.save
    end

    # Deletes the document from the database. Runs the :destroy callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    def destroy(bulk=false)
      caught = catch(:halt)  do
        _run_destroy_callbacks do
          result = database.delete_doc(self, bulk)
          if result['ok']
            self.delete('_rev')
            self.delete('_id')
          end
          result['ok']
        end
      end
    end
    
  end
end
