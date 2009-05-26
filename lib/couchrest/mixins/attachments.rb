module CouchRest
  module Mixins
    module Attachments
    
      # saves an attachment directly to couchdb
      def put_attachment(name, file, options={})
        raise ArgumentError, "doc must be saved" unless self.rev
        raise ArgumentError, "doc.database required to put_attachment" unless database
        result = database.put_attachment(self, name, file, options)
        self['_rev'] = result['rev']
        result['ok']
      end

      # returns an attachment's data
      def fetch_attachment(name)
        raise ArgumentError, "doc must be saved" unless self.rev
        raise ArgumentError, "doc.database required to put_attachment" unless database
        database.fetch_attachment(self, name)
      end

      # deletes an attachment directly from couchdb
      def delete_attachment(name)
        raise ArgumentError, "doc.database required to delete_attachment" unless database
        result = database.delete_attachment(self, name)
        self['_rev'] = result['rev']
        result['ok']
      end
    
    end
  end
end