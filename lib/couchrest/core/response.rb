module CouchRest
  class Response < Hash
    def initialize(pkeys = {})
      pkeys ||= {}
      pkeys.each do |k,v|
        self[k.to_s] = v
      end
    end
    def []=(key, value)
      super(key.to_s, value)
    end
    def [](key)
      super(key.to_s)
    end
  end
end