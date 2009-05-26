module CouchRest  
  class Design < Document
    def view_by *keys
      opts = keys.pop if keys.last.is_a?(Hash)
      opts ||= {}
      self['views'] ||= {}
      method_name = "by_#{keys.join('_and_')}"
      
      if opts[:map]
        view = {}
        view['map'] = opts.delete(:map)
        if opts[:reduce]
          view['reduce'] = opts.delete(:reduce)
          opts[:reduce] = false
        end
        self['views'][method_name] = view
      else
        doc_keys = keys.collect{|k|"doc['#{k}']"} # this is where :require => 'doc.x == true' would show up
        key_emit = doc_keys.length == 1 ? "#{doc_keys.first}" : "[#{doc_keys.join(', ')}]"
        guards = opts.delete(:guards) || []
        guards.concat doc_keys
        map_function = <<-JAVASCRIPT
function(doc) {
  if (#{guards.join(' && ')}) {
    emit(#{key_emit}, null);
  }
}
JAVASCRIPT
        self['views'][method_name] = {
          'map' => map_function
        }
      end
      self['views'][method_name]['couchrest-defaults'] = opts unless opts.empty?
      method_name
    end
    
    # Dispatches to any named view.
    # (using the database where this design doc was saved)
    def view view_name, query={}, &block
      view_on database, view_name, query, &block
    end

    # Dispatches to any named view in a specific database
    def view_on db, view_name, query={}, &block
      view_name = view_name.to_s
      view_slug = "#{name}/#{view_name}"
      defaults = (self['views'][view_name] && self['views'][view_name]["couchrest-defaults"]) || {}
      db.view(view_slug, defaults.merge(query), &block)
    end

    def name
      id.sub('_design/','') if id
    end

    def name= newname
      self['_id'] = "_design/#{newname}"
    end

    def save
      raise ArgumentError, "_design docs require a name" unless name && name.length > 0
      super
    end

    private

    # returns stored defaults if the there is a view named this in the design doc
    def has_view?(view)
      view = view.to_s
      self['views'][view] &&
        (self['views'][view]["couchrest-defaults"]||{})
    end

    def fetch_view view_name, opts, &block
      database.view(view_name, opts, &block)
    end

  end
  
end