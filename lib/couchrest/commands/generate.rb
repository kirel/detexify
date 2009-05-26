require 'fileutils'

module CouchRest
  module Commands
    module Generate

      def self.run(options)
        directory    = options[:directory]
        design_names = options[:trailing_args]

        FileUtils.mkdir_p(directory)
        filename = File.join(directory, "lib.js")
        self.write(filename, <<-FUNC)
        // Put global functions here.
        // Include in your views with
        //
        //   //include-lib
        FUNC

        design_names.each do |design_name|
          subdirectory = File.join(directory, design_name)
          FileUtils.mkdir_p(subdirectory)
          filename = File.join(subdirectory, "sample-map.js")
          self.write(filename, <<-FUNC)
          function(doc) {
            // Keys is first letter of _id
            emit(doc._id[0], doc);
          }
          FUNC

          filename = File.join(subdirectory, "sample-reduce.js")
          self.write(filename, <<-FUNC)
          function(keys, values) {
            // Count the number of keys starting with this letter
            return values.length;
          }
          FUNC

          filename = File.join(subdirectory, "lib.js")
          self.write(filename, <<-FUNC)
          // Put functions specific to '#{design_name}' here.
          // Include in your views with
          //
          //   //include-lib
          FUNC
        end
      end

      def self.help
        helpstring = <<-GEN

        Usage: couchview generate directory design1 design2 design3 ...

        Couchview will create directories and example views for the design documents you specify.

        GEN
        helpstring.gsub(/^        /, '')
      end

      def self.write(filename, contents)
        puts "Writing #{filename}"
        File.open(filename, "w") do |f|
          # Remove leading spaces
          contents.gsub!(/^        (  )?/, '')
          f.write contents
        end
      end

    end
  end
end
