module CouchRest

  module Commands

    module Push

      def self.run(options)
        directory = options[:directory]
        database  = options[:trailing_args].first
        
        fm      = CouchRest::FileManager.new(database)
        fm.loud = options[:loud]

        if options[:loud]
          puts "Pushing views from directory #{directory} to database #{fm.db}"
        end

        fm.push_views(directory)
      end

      def self.help
        helpstring = <<-GEN

        == Pushing views with Couchview ==

        Usage: couchview push directory dbname

        Couchview expects a specific filesystem layout for your CouchDB views (see
        example below). It also supports advanced features like inlining of library
        code (so you can keep DRY) as well as avoiding unnecessary document
        modification.

        Couchview also solves a problem with CouchDB's view API, which only provides
        access to the final reduce side of any views which have both a map and a
        reduce function defined. The intermediate map results are often useful for
        development and production. CouchDB is smart enough to reuse map indexes for
        functions duplicated across views within the same design document.

        For views with a reduce function defined, Couchview creates both a reduce view
        and a map-only view, so that you can browse and query the map side as well as
        the reduction, with no performance penalty.

        == Example ==

        couchview push foo-project/bar-views baz-database

        This will push the views defined in foo-project/bar-views into a database
        called baz-database. Couchview expects the views to be defined in files with
        names like:

        foo-project/bar-views/my-design/viewname-map.js
        foo-project/bar-views/my-design/viewname-reduce.js
        foo-project/bar-views/my-design/noreduce-map.js

        Pushed to => http://127.0.0.1:5984/baz-database/_design/my-design

        And the design document:
        {
          "views" : {
            "viewname-map" : {
              "map" : "### contents of view-name-map.js ###"
            },
            "viewname-reduce" : {
              "map" : "### contents of view-name-map.js ###",
              "reduce" : "### contents of view-name-reduce.js ###"
            },
            "noreduce-map" : {
              "map" : "### contents of noreduce-map.js ###"
            }
          }
        }

        Couchview will create a design document for each subdirectory of the views
        directory specified on the command line.

        == Library Inlining ==

        Couchview can optionally inline library code into your views so you only have
        to maintain it in one place. It looks for any files named lib.* in your
        design-doc directory (for doc specific libs) and in the parent views directory
        (for project global libs). These libraries are only inserted into views which
        include the text

        // !include lib

        or

        # !include lib

        Couchview is a result of scratching my own itch. I'd be happy to make it more
        general, so please contact me at jchris@grabb.it if you'd like to see anything
        added or changed.

        GEN
        helpstring.gsub(/^        /, '')
      end

    end


  end

end
