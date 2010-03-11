require 'base64'
require 'httparty'

module Classinatra
  module Client
    module InstanceMethods
      def stats
        stats = self.class.get("/").symbolize_keys!
        stats.update :counts => stats[:counts].inject({}) { |h,kv| h.update Base64.decode64(kv.first) => kv.last }
      end

      def classify data
        self.class.post("/classify", { :body => data }).map { |h| h.symbolize_keys!.update :id => Base64.decode64(h[:id]) }
      end

      def train id, data
        self.class.post "/train/#{Base64.encode64(id.to_s)}", { :body => data }
      end
    end

    def self.at uri
      Class.new do
        include HTTParty
        base_uri uri
        format :json
        include InstanceMethods
      end.new
    end
  end
end

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
  
  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end
end