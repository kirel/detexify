# Extracted from dm-validations 0.9.10
#
# Copyright (c) 2007 Guy van den Berg
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module CouchRest
  module Validation

    ##
    #
    # @author Guy van den Berg
    # @since  0.9
    class MethodValidator < GenericValidator

      def initialize(field_name, options={})
        super
        @field_name, @options = field_name, options.clone
        @options[:method] = @field_name unless @options.has_key?(:method)
      end

      def call(target)
        result, message = target.send(@options[:method])
        add_error(target, message, field_name) unless result
        result
      end

      def ==(other)
        @options[:method] == other.instance_variable_get(:@options)[:method] && super
      end
    end # class MethodValidator

    module ValidatesWithMethod

      ##
      # Validate using the given method. The method given needs to return:
      # [result::<Boolean>, Error Message::<String>]
      #
      # @example [Usage]
      #
      #   class Page
      #
      #     property :zip_code, String
      #
      #     validates_with_method :in_the_right_location?
      #
      #     def in_the_right_location?
      #       if @zip_code == "94301"
      #         return true
      #       else
      #         return [false, "You're in the wrong zip code"]
      #       end
      #     end
      #
      #     # A call to valid? will return false and
      #     # populate the object's errors with "You're in the
      #     # wrong zip code" unless zip_code == "94301"
      #
      #     # You can also specify field:
      #
      #     validates_with_method :zip_code, :in_the_right_location?
      #
      #     # it will add returned error message to :zip_code field
      #
      def validates_with_method(*fields)
        opts = opts_from_validator_args(fields)
        add_validator_to_context(opts, fields, CouchRest::Validation::MethodValidator)
      end

    end # module ValidatesWithMethod
  end # module Validation
end # module CouchRest
