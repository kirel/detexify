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
    class NumericValidator < GenericValidator

      def initialize(field_name, options={})
        super
        @field_name, @options = field_name, options
        @options[:integer_only] = false unless @options.has_key?(:integer_only)
      end

      def call(target)
        value = target.send(field_name)
        return true if @options[:allow_nil] && value.nil?

        value = value.kind_of?(Float) ? value.to_s('F') : value.to_s

        error_message = @options[:message]
        precision     = @options[:precision]
        scale         = @options[:scale]

        if @options[:integer_only]
          return true if value =~ /\A[+-]?\d+\z/
          error_message ||= ValidationErrors.default_error_message(:not_an_integer, field_name)
        else
          # FIXME: if precision and scale are not specified, can we assume that it is an integer?
          #        probably not, as floating point numbers don't have hard
          #        defined scale. the scale floats with the length of the
          #        integral and precision. Ie. if precision = 10 and integral
          #        portion of the number is 9834 (4 digits), the max scale will
          #        be 6 (10 - 4). But if the integral length is 1, max scale
          #        will be (10 - 1) = 9, so 1.234567890.
          if precision && scale
            #handles both Float when it has scale specified and BigDecimal
            if precision > scale && scale > 0
              return true if value =~ /\A[+-]?(?:\d{1,#{precision - scale}}|\d{0,#{precision - scale}}\.\d{1,#{scale}})\z/
            elsif precision > scale && scale == 0
              return true if value =~ /\A[+-]?(?:\d{1,#{precision}}(?:\.0)?)\z/
            elsif precision == scale
              return true if value =~ /\A[+-]?(?:0(?:\.\d{1,#{scale}})?)\z/
            else
              raise ArgumentError, "Invalid precision #{precision.inspect} and scale #{scale.inspect} for #{field_name} (value: #{value.inspect} #{value.class})"
            end
          elsif precision && scale.nil?
            # for floats, if scale is not set

            #total number of digits is less or equal precision
            return true if value.gsub(/[^\d]/, '').length <= precision

            #number of digits before decimal == precision, and the number is x.0. same as scale = 0
            return true if value =~ /\A[+-]?(?:\d{1,#{precision}}(?:\.0)?)\z/
          else
            return true if value =~ /\A[+-]?(?:\d+|\d*\.\d+)\z/
          end
          error_message ||= ValidationErrors.default_error_message(:not_a_number, field_name)
        end

        add_error(target, error_message, field_name)

        # TODO: check the gt, gte, lt, lte, and eq options

        return false
      end
    end # class NumericValidator

    module ValidatesIsNumber

      # Validate whether a field is numeric
      #
      def validates_is_number(*fields)
        opts = opts_from_validator_args(fields)
        add_validator_to_context(opts, fields, CouchRest::Validation::NumericValidator)
      end

    end # module ValidatesIsNumber
  end # module Validation
end # module CouchRest
