module CouchRest
  module Mixins

    module ExtendedEnumerable
      DEFAULT_BATCHSIZE = 25

      def self.included(base)
        base.class_eval do
          view_by :_id
        end
        base.extend ClassMethods
        base.extend Enumerable
      end

      module ClassMethods
        def batch(num = DEFAULT_BATCHSIZE, opts = {}, &block)
          b = self.all(opts.merge!(:limit => num+1))
          while b.size == num+1
            this_batch, start = b[0..-2], b[-1]
            yield this_batch
            b = self.by__id(opts.merge!(:limit => num+1, :startkey => start.id))
          end
          yield b
        end

        def each(&block)
          self.batch do |b|
            b.each do |s|
              yield s
            end
          end
        end
      end
    end

  end
  
  ExtendedDocument.send :include, Mixins::ExtendedEnumerable
end
