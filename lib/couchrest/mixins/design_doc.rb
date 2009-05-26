require 'digest/md5'

module CouchRest
  module Mixins
    module DesignDoc
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        attr_accessor :design_doc, :design_doc_slug_cache, :design_doc_fresh
        
        def design_doc
          @design_doc ||= Design.new(default_design_doc)
        end
        
        def design_doc_id
          "_design/#{design_doc_slug}"
        end

        def design_doc_slug
          return design_doc_slug_cache if (design_doc_slug_cache && design_doc_fresh)
          funcs = []
          design_doc['views'].each do |name, view|
            funcs << "#{name}/#{view['map']}#{view['reduce']}"
          end
          self.design_doc_slug_cache = self.to_s
        end

        def default_design_doc
          {
            "language" => "javascript",
            "views" => {
              'all' => {
                'map' => "function(doc) {
                  if (doc['couchrest-type'] == '#{self.to_s}') {
                    emit(null,null);
                  }
                }"
              }
            }
          }
        end

        def refresh_design_doc
          reset_design_doc
          save_design_doc
        end

        # Save the design doc onto the default database, and update the
        # design_doc attribute
        def save_design_doc
          reset_design_doc unless design_doc_fresh
          self.design_doc = update_design_doc(design_doc)
        end

        # Save the design doc onto a target database in a thread-safe way,
        # not modifying the model's design_doc
        def save_design_doc_on(db)
          update_design_doc(Design.new(design_doc), db)
        end

        private
        
        def reset_design_doc
          design_doc['_id'] = design_doc_id
          design_doc.delete('_rev')
          #design_doc.database = nil
          self.design_doc_fresh = true
        end

        # Writes out a design_doc to a given database, returning the
        # updated design doc
        def update_design_doc(design_doc, db = database)
          saved = db.get(design_doc['_id']) rescue nil
          if saved
            design_doc['views'].each do |name, view|
              saved['views'][name] = view
            end
            db.save_doc(saved)
            saved
          else
            design_doc.database = db
            design_doc.save
            design_doc
          end
        end
        
      end # module ClassMethods
      
    end
  end
end