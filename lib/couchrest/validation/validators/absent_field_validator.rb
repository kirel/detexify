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
    class AbsentFieldValidator < GenericValidator

      def initialize(field_name, options={})
        super
        @field_name, @options = field_name, options
      end

      def call(target)
        value = target.send(field_name)
        return true if (value.nil? || (value.respond_to?(:empty?) && value.empty?))

        error_message = @options[:message] || ValidationErrors.default_error_message(:absent, field_name)
        add_error(target, error_message, field_name)

        return false
      end
    end # class AbsentFieldValidator

    module ValidatesAbsent

      ##
      #
      # @example [Usage]
      #
      #   class Page
      #
      #     property :unwanted_attribute, String
      #     property :another_unwanted, String
      #     property :yet_again, String
      #
      #     validates_absent :unwanted_attribute
      #     validates_absent :another_unwanted, :yet_again
      #
      #     # a call to valid? will return false unless
      #     # all three attributes are blank
      #   end
      #
      def validates_absent(*fields)
        opts = opts_from_validator_args(fields)
        add_validator_to_context(opts, fields, CouchRest::Validation::AbsentFieldValidator)
      end

    end # module ValidatesAbsent
  end # module Validation
end # module CouchRest
