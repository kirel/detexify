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
    class ContextualValidators

      def dump
        contexts.each_pair do |key, context|
          puts "Key=#{key} Context: #{context}"
        end
      end

      # Get a hash of named context validators for the resource
      #
      # @return <Hash> a hash of validators <GenericValidator>
      def contexts
        @contexts ||= {}
      end

      # Return an array of validators for a named context
      #
      # @return <Array> An array of validators
      def context(name)
        contexts[name] ||= []
      end

      # Clear all named context validators off of the resource
      #
      def clear!
        contexts.clear
      end

      # Execute all validators in the named context against the target
      #
      # @param <Symbol> named_context the context we are validating against
      # @param <Object> target        the resource that we are validating
      # @return <Boolean> true if all are valid, otherwise false
      def execute(named_context, target)
        raise(ArgumentError, 'invalid context specified') if !named_context || (contexts.length > 0 && !contexts[named_context])
        target.errors.clear!
        result = true
        context(named_context).each do |validator|
          next unless validator.execute?(target)
          result = false unless validator.call(target)
        end

        result
      end

    end # module ContextualValidators
  end # module Validation
end # module CouchRest
