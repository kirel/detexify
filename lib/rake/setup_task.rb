require 'rake/tasklib'
require 'couchrest'

class SetupTask < Rake::TaskLib

  # initialize sets the name and calls a block to get
  #   the rest of the options
  def initialize
      yield self if block_given?
      define
  end

  # define creates the new task(s)
  def define
    desc "setup couchdb views"
    task :setup do
      unless ENV['COUCH']
        abort "You must set COUCH environment variable!"
      end

      @db = CouchRest.database!(ENV['COUCH'])

      begin
        @db.get("_design/tools")
      rescue RestClient::ResourceNotFound
        @db.save_doc({
          "_id" => "_design/tools",
          :views => {
            :by_id => {
              :map => <<-JS.split.map(&:strip).join,
                function(doc) { if (doc.id) emit(doc.id, null); }
              JS
              :reduce => <<-JS.split.map(&:strip).join
               _count
              JS
            }
          }
        })
      end
    end
  end


end