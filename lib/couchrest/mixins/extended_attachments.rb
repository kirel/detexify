module CouchRest
  module Mixins
    module ExtendedAttachments

      # creates a file attachment to the current doc
      def create_attachment(args={})
        raise ArgumentError unless args[:file] && args[:name]
        return if has_attachment?(args[:name])
        self['_attachments'] ||= {}
        set_attachment_attr(args) # Fixme use put_attachment?
      rescue ArgumentError => e
        raise ArgumentError, 'You must specify :file and :name'
      end

      # reads the data from an attachment
      def read_attachment(attachment_name)
        database.fetch_attachment(self, attachment_name)
      end

      # modifies a file attachment on the current doc
      def update_attachment(args={})
        raise ArgumentError unless args[:file] && args[:name]
        return unless has_attachment?(args[:name])
        delete_attachment(args[:name])
        set_attachment_attr(args) # Fixme use put_attachment?
      rescue ArgumentError => e
        raise ArgumentError, 'You must specify :file and :name'
      end

      # deletes a file attachment from the current doc
      def delete_attachment(attachment_name)
        return unless self['_attachments']
        self['_attachments'].delete attachment_name
      end

      # returns true if attachment_name exists
      def has_attachment?(attachment_name)
        !!(self['_attachments'] && self['_attachments'][attachment_name] && !self['_attachments'][attachment_name].empty?)
      end

      # returns URL to fetch the attachment from
      def attachment_url(attachment_name)
        return unless has_attachment?(attachment_name)
        "#{database.root}/#{self.id}/#{attachment_name}"
      end
      
      private
      
        def get_mime_type(file)
          ::MIME::Types.type_for(file.path).empty? ? 
            'text/plain' : MIME::Types.type_for(file.path).first.content_type#.gsub(/\//,'\/')
        end

        def set_attachment_attr(args) # Fixme use put_attachment?
          content_type = args[:content_type] ? args[:content_type] : get_mime_type(args[:file])
          self['_attachments'][args[:name]] = {
            'content_type' => content_type,
            'data'         => args[:file].read
          }
        end
      
    end # module ExtendedAttachments
  end
end