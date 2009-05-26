# -*- coding: utf-8 -*-

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

    # All validators extend this base class. Validators must:
    #
    # * Implement the initialize method to capture its parameters, also calling
    #   super to have this parent class capture the optional, general :if and
    #   :unless parameters.
    # * Implement the call method, returning true or false. The call method
    #   provides the validation logic.
    #
    # @author Guy van den Berg
    class GenericValidator

      attr_accessor :if_clause, :unless_clause
      attr_reader :field_name

      # Construct a validator. Capture the :if and :unless clauses when present.
      #
      # @param field<String, Symbol> The property specified for validation
      #
      # @option :if<Symbol, Proc>   The name of a method or a Proc to call to
      #                     determine if the validation should occur.
      # @option :unless<Symbol, Proc> The name of a method or a Proc to call to
      #                         determine if the validation should not occur
      # All additional key/value pairs are passed through to the validator
      # that is sub-classing this GenericValidator
      #
      def initialize(field, opts = {})
        @if_clause     = opts.delete(:if)
        @unless_clause = opts.delete(:unless)
      end

      # Add an error message to a target resource. If the error corresponds to a
      # specific field of the resource, add it to that field, otherwise add it
      # as a :general message.
      #
      # @param <Object> target the resource that has the error
      # @param <String> message the message to add
      # @param <Symbol> field_name the name of the field that caused the error
      #
      # TODO - should the field_name for a general message be :default???
      #
      def add_error(target, message, field_name = :general)
        target.errors.add(field_name, message)
      end

      # Call the validator. "call" is used so the operation is BoundMethod and
      # Block compatible. This must be implemented in all concrete classes.
      #
      # @param <Object> target  the resource that the validator must be called
      #                         against
      # @return <Boolean> true if valid, otherwise false
      def call(target)
        raise NotImplementedError, "CouchRest::Validation::GenericValidator::call must be overriden in a subclass"
      end

      # Determines if this validator should be run against the
      # target by evaluating the :if and :unless clauses
      # optionally passed while specifying any validator.
      #
      # @param <Object> target the resource that we check against
      # @return <Boolean> true if should be run, otherwise false
      def execute?(target)
        if unless_clause = self.unless_clause
          if unless_clause.is_a?(Symbol)
            return false if target.send(unless_clause)
          elsif unless_clause.respond_to?(:call)
            return false if unless_clause.call(target)
          end
        end

        if if_clause = self.if_clause
          if if_clause.is_a?(Symbol)
            return target.send(if_clause)
          elsif if_clause.respond_to?(:call)
            return if_clause.call(target)
          end
        end

        true
      end

      def ==(other)
        self.class == other.class &&
        self.field_name == other.field_name &&
        self.class == other.class &&
        self.if_clause == other.if_clause &&
        self.unless_clause == other.unless_clause &&
        self.instance_variable_get(:@options) == other.instance_variable_get(:@options)
      end

    end # class GenericValidator
  end # module Validation
end # module CouchRest
