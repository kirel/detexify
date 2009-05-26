module CouchRest
  module Mixins
    module DocumentQueries
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        # Load all documents that have the "couchrest-type" field equal to the
        # name of the current class. Take the standard set of
        # CouchRest::Database#view options.
        def all(opts = {}, &block)
          view(:all, opts, &block)
        end

        # Load the first document that have the "couchrest-type" field equal to
        # the name of the current class.
        #
        # ==== Returns
        # Object:: The first object instance available
        # or
        # Nil:: if no instances available
        #
        # ==== Parameters
        # opts<Hash>::
        # View options, see <tt>CouchRest::Database#view</tt> options for more info.
        def first(opts = {})
          first_instance = self.all(opts.merge!(:limit => 1))
          first_instance.empty? ? nil : first_instance.first
        end
        
        # Load a document from the database by id
        def get(id, db = database)
          doc = db.get id
          new(doc)
        end
        
      end
      
    end
  end
end