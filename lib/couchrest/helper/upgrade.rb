module CouchRest
  class Upgrade
    attr_accessor :olddb, :newdb, :dbname
    def initialize dbname, old_couch, new_couch
      @dbname = dbname
      @olddb = old_couch.database dbname
      @newdb = new_couch.database!(dbname)
      @bulk_docs = []
    end
    def clone!
      puts "#{dbname} - #{olddb.info['doc_count']} docs"
      streamer  = CouchRest::Streamer.new(olddb)
      streamer.view("_all_docs_by_seq") do |row|
        load_row_docs(row) if row
        maybe_flush_bulks
      end
      flush_bulks!
    end
    
    private
    
    def maybe_flush_bulks
      flush_bulks! if (@bulk_docs.length > 99)
    end
    
    def flush_bulks!
      url = CouchRest.paramify_url "#{@newdb.uri}/_bulk_docs", {:all_or_nothing => true}
      puts "posting #{@bulk_docs.length} bulk docs to #{url}"
      begin
        CouchRest.post url, {:docs => @bulk_docs}      
        @bulk_docs = []
      rescue Exception => e
        puts e.response
        raise e
      end
    end
    
    def load_row_docs(row)
      results = @olddb.get(row["id"], {:open_revs => "all", :attachments => true})
      results.select{|r|r["ok"]}.each do |r|
        doc = r["ok"]
        if /^_/.match(doc["_id"]) && !/^_design/.match(doc["_id"])
          puts "invalid docid #{doc["_id"]} -- trimming"
          doc["_id"] = doc["_id"].sub('_','')
        end
        doc.delete('_rev')
        @bulk_docs << doc
      end
    end
  end
end
