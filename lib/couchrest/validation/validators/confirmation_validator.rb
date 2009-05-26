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
    class ConfirmationValidator < GenericValidator

      def initialize(field_name, options = {})
        super
        @options = options
        @field_name, @confirm_field_name = field_name, (options[:confirm] || "#{field_name}_confirmation").to_sym
        @options[:allow_nil] = true unless @options.has_key?(:allow_nil)
      end

      def call(target)
        unless valid?(target)
          error_message = @options[:message] || ValidationErrors.default_error_message(:confirmation, field_name)
          add_error(target, error_message, field_name)
          return false
        end

        return true
      end

      def valid?(target)
        field_value = target.send(field_name)
        return true if @options[:allow_nil] && field_value.nil?
        return false if !@options[:allow_nil] && field_value.nil?

        confirm_value = target.instance_variable_get("@#{@confirm_field_name}")
        field_value == confirm_value
      end

    end # class ConfirmationValidator

    module ValidatesIsConfirmed

      ##
      # Validates that the given attribute is confirmed by another attribute.
      # A common use case scenario is when you require a user to confirm their
      # password, for which you use both password and password_confirmation
      # attributes.
      #
      # @option :allow_nil<Boolean> true/false (default is true)
      # @option :confirm<Symbol>    the attribute that you want to validate
      #                             against (default is firstattr_confirmation)
      #
      # @example [Usage]
      #
      #   class Page < Hash
      #     include CouchRest::ExtendedModel
      #     include CouchRest::Validations
      #
      #     property :password, String
      #     property :email, String
      #     attr_accessor :password_confirmation
      #     attr_accessor :email_repeated
      #
      #     validates_is_confirmed :password
      #     validates_is_confirmed :email, :confirm => :email_repeated
      #
      #     # a call to valid? will return false unless:
      #     # password == password_confirmation
      #     # and
      #     # email == email_repeated
      #
      def validates_is_confirmed(*fields)
        opts = opts_from_validator_args(fields)
        add_validator_to_context(opts, fields, CouchRest::Validation::ConfirmationValidator)
      end

    end # module ValidatesIsConfirmed
  end # module Validation
end # module CouchRest
