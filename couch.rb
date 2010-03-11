require 'rest_client'
require 'json'

class Couch
  include Enumerable
  
  def initialize dburl
    @dburl = dburl
  end
    
  # %w(get post put delete).each do |method|
  #   define_method method do |*args|
  #     args.first = @dburl + args.first
  #     RestClient.send method, *args
  #   end    
  # end
  
  def create!
    RestClient.get @dburl, :accept => :json do |response|
      case response.code
      when 404
        RestClient.put @dburl, nil, :content_type => :json, :accept => :json
      else
        response.return!
      end
    end
  end
  
  def << doc
    RestClient.post @dburl, JSON(doc), :content_type => :json, :accept => :json do |response|
      response.return! unless response.code == 201
    end
    self
  end
  
  def size
    RestClient.get(@dburl + '_all_docs?limit=0', :accept => :json) do |r|
      case r.code
      when 200
        JSON(r.body)['total_rows']
      else
        r.return!
      end
    end
  end
  
  def each
    # iterate in batches of @batch_size
    @batch_size = 100
    # initial query
    res = RestClient.get(@dburl + "_all_docs?limit=#{@batch_size+1}&include_docs=true", :accept => :json) do |r|
      case r.code
      when 200
        JSON(r.body)
      else
        r.return!
      end
    end
    rows = res['rows']
    last = rows.size > @batch_size ? rows.pop : nil
    rows.each { |row| yield row['doc'] }
    # subsequent queries
    while last
      startkey = last['key']
      res = RestClient.get(@dburl+"_all_docs?startkey=%22#{startkey}%22&limit=#{@batch_size+1}&include_docs=true", :accept => :json) do |r|
        case r.code
        when 200
          JSON(r.body)
        else
          r.return!
        end
      end
      rows = res['rows']
      last = rows.size > @batch_size ? rows.pop : nil
      rows.each { |row| yield row['doc'] }
    end
  end
end