require 'restclient'
require 'json'

class Couch
  include Enumerable
  
  def initialize dburl
    @dburl = dburl
  end
    
  %w(get post put delete).each do |method|
    define_method method do |*args|
      args.first = @dburl + args.first
      RestClient.send method, *args
    end    
  end
  
  def create!
    RestClient.get @dburl rescue RestClient.put @dburl, nil
  end
  
  def << doc
    RestClient.post @dburl, JSON(doc)
    self
  end
  
  def size
    JSON(RestClient.get(@dburl + '_all_docs?limit=0'))['total_rows']
  end
  
  def each
    # iterate in batches of @batch_size
    @batch_size = 100
    # initial query
    res = JSON(RestClient.get(@dburl + "_all_docs?limit=#{@batch_size+1}&include_docs=true"))
    rows = res['rows']
    last = rows.size > @batch_size ? rows.pop : nil
    rows.each { |row| yield row['doc'] }
    # subsequent queries
    while last
      startkey = last['key']
      res = JSON(RestClient.get(@dburl + "_all_docs?startkey=%22#{startkey}%22&limit=#{@batch_size+1}&include_docs=true"))
      rows = res['rows']
      last = rows.size > @batch_size ? rows.pop : nil
      rows.each { |row| yield row['doc'] }
    end
  end
end