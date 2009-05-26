module CouchRest
  module Mixins
    module Views
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # Define a CouchDB view. The name of the view will be the concatenation
        # of <tt>by</tt> and the keys joined by <tt>_and_</tt>
        #  
        # ==== Example views:
        #  
        #   class Post
        #     # view with default options
        #     # query with Post.by_date
        #     view_by :date, :descending => true
        #  
        #     # view with compound sort-keys
        #     # query with Post.by_user_id_and_date
        #     view_by :user_id, :date
        #  
        #     # view with custom map/reduce functions
        #     # query with Post.by_tags :reduce => true
        #     view_by :tags,                                                
        #       :map =>                                                     
        #         "function(doc) {                                          
        #           if (doc['couchrest-type'] == 'Post' && doc.tags) {                   
        #             doc.tags.forEach(function(tag){                       
        #               emit(doc.tag, 1);                                   
        #             });                                                   
        #           }                                                       
        #         }",                                                       
        #       :reduce =>                                                  
        #         "function(keys, values, rereduce) {                       
        #           return sum(values);                                     
        #         }"                                                        
        #   end
        #  
        # <tt>view_by :date</tt> will create a view defined by this Javascript
        # function:
        #  
        #   function(doc) {
        #     if (doc['couchrest-type'] == 'Post' && doc.date) {
        #       emit(doc.date, null);
        #     }
        #   }
        #  
        # It can be queried by calling <tt>Post.by_date</tt> which accepts all
        # valid options for CouchRest::Database#view. In addition, calling with
        # the <tt>:raw => true</tt> option will return the view rows
        # themselves. By default <tt>Post.by_date</tt> will return the
        # documents included in the generated view.
        #  
        # Calling with :database => [instance of CouchRest::Database] will
        # send the query to a specific database, otherwise it will go to
        # the model's default database (use_database)
        #  
        # CouchRest::Database#view options can be applied at view definition
        # time as defaults, and they will be curried and used at view query
        # time. Or they can be overridden at query time.
        #  
        # Custom views can be queried with <tt>:reduce => true</tt> to return
        # reduce results. The default for custom views is to query with
        # <tt>:reduce => false</tt>.
        #  
        # Views are generated (on a per-model basis) lazily on first-access.
        # This means that if you are deploying changes to a view, the views for
        # that model won't be available until generation is complete. This can
        # take some time with large databases. Strategies are in the works.
        #  
        # To understand the capabilities of this view system more completely,
        # it is recommended that you read the RSpec file at
        # <tt>spec/core/model_spec.rb</tt>.

        def view_by(*keys)
          opts = keys.pop if keys.last.is_a?(Hash)
          opts ||= {}
          ducktype = opts.delete(:ducktype)
          unless ducktype || opts[:map]
            opts[:guards] ||= []
            opts[:guards].push "(doc['couchrest-type'] == '#{self.to_s}')"
          end
          keys.push opts
          self.design_doc.view_by(*keys)
          self.design_doc_fresh = false
        end

        # returns stored defaults if the there is a view named this in the design doc
        def has_view?(view)
          view = view.to_s
          design_doc && design_doc['views'] && design_doc['views'][view]
        end

        # Dispatches to any named view.
        def view(name, query={}, &block)
          unless design_doc_fresh
            refresh_design_doc
          end
          query[:raw] = true if query[:reduce]        
          db = query.delete(:database) || database
          raw = query.delete(:raw)
          fetch_view_with_docs(db, name, query, raw, &block)
        end

        # DEPRECATED
        # user model_design_doc to retrieve the current design doc
        def all_design_doc_versions(db = database)
          db.documents :startkey => "_design/#{self.to_s}", 
            :endkey => "_design/#{self.to_s}-\u9999"
        end
        
        def model_design_doc(db = database)
          begin
            @model_design_doc = db.get("_design/#{self.to_s}")
          rescue
            nil
          end
        end

        # Deletes the current design doc for the current class.
        # Running it to early could mean that live code has to regenerate
        # potentially large indexes.
        def cleanup_design_docs!(db = database)
          save_design_doc_on(db)
          # db.refresh_design_doc
          #           db.save_design_doc
          # design_doc = model_design_doc(db)
          # if design_doc
          #   db.delete_doc(design_doc)
          # else
          #   false
          # end
        end

        private

        def fetch_view_with_docs(db, name, opts, raw=false, &block)
          if raw || (opts.has_key?(:include_docs) && opts[:include_docs] == false)
            fetch_view(db, name, opts, &block)
          else
            begin
              view = fetch_view db, name, opts.merge({:include_docs => true}), &block
              view['rows'].collect{|r|new(r['doc'])} if view['rows']
            rescue
              # fallback for old versions of couchdb that don't 
              # have include_docs support
              view = fetch_view(db, name, opts, &block)
              view['rows'].collect{|r|new(db.get(r['id']))} if view['rows']
            end
          end
        end

        def fetch_view(db, view_name, opts, &block)
          raise "A view needs a database to operate on (specify :database option, or use_database in the #{self.class} class)" unless db
          retryable = true
          begin
            design_doc.view_on(db, view_name, opts, &block)
            # the design doc may not have been saved yet on this database
          rescue RestClient::ResourceNotFound => e
            if retryable
              save_design_doc_on(db)
              retryable = false
              retry
            else
              raise e
            end
          end
        end
        
      end # module ClassMethods
      
      
    end
  end
end