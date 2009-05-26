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

class Object
  def validatable?
    false
  end
end

require 'pathname'
require File.join(File.dirname(__FILE__), '..', 'support', 'class')

dir = File.join(Pathname(__FILE__).dirname.expand_path, '..', 'validation')

require File.join(dir, 'validation_errors')
require File.join(dir, 'contextual_validators')
require File.join(dir, 'auto_validate')

require File.join(dir, 'validators', 'generic_validator')
require File.join(dir, 'validators', 'required_field_validator')
require File.join(dir, 'validators', 'absent_field_validator')
require File.join(dir, 'validators', 'format_validator')
require File.join(dir, 'validators', 'length_validator')
require File.join(dir, 'validators', 'numeric_validator')
require File.join(dir, 'validators', 'method_validator')
require File.join(dir, 'validators', 'confirmation_validator')

module CouchRest
  module Validation
    
    def self.included(base)
      base.extlib_inheritable_accessor(:auto_validation)
      base.class_eval <<-EOS, __FILE__, __LINE__
          # Turn off auto validation by default
          self.auto_validation ||= false
          
          # Force the auto validation for the class properties
          # This feature is still not fully ported over,
          # test are lacking, so please use with caution
          def self.auto_validate!
            self.auto_validation = true
          end
          
          # share the validations with subclasses
          def self.inherited(subklass)
            self.validators.contexts.each do |k, v|
              subklass.validators.contexts[k] = v.dup
            end
            super
          end
      EOS
      
      base.extend(ClassMethods)
      base.class_eval <<-EOS, __FILE__, __LINE__
        if method_defined?(:_run_save_callbacks)
          save_callback :before, :check_validations
        end
      EOS
      base.class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def self.define_property(name, options={})
          super
          auto_generate_validations(properties.last) if properties && properties.size > 0
          autovalidation_check = true
        end
      RUBY_EVAL
    end

    # Ensures the object is valid for the context provided, and otherwise
    # throws :halt and returns false.
    #
    def check_validations(context = :default)
      throw(:halt, false) unless context.nil? || valid?(context)
    end
    
    # Return the ValidationErrors
    #
    def errors
      @errors ||= ValidationErrors.new
    end

    # Mark this resource as validatable. When we validate associations of a
    # resource we can check if they respond to validatable? before trying to
    # recursivly validate them
    #
    def validatable?
      true
    end

    # Alias for valid?(:default)
    #
    def valid_for_default?
      valid?(:default)
    end

    # Check if a resource is valid in a given context
    #
    def valid?(context = :default)
      result = self.class.validators.execute(context, self)
      result && validate_casted_arrays
    end
    
    # checking on casted objects
    def validate_casted_arrays
      result = true
      array_casted_properties = self.class.properties.select { |property| property.casted && property.type.instance_of?(Array) }
      array_casted_properties.each do |property|
        casted_values = self.send(property.name)
        next unless casted_values.is_a?(Array) && casted_values.first.respond_to?(:valid?)
        casted_values.each do |value|
          result = (result && value.valid?) if value.respond_to?(:valid?)
        end
      end
      result
    end

    # Begin a recursive walk of the model checking validity
    #
    def all_valid?(context = :default)
      recursive_valid?(self, context, true)
    end

    # Do recursive validity checking
    #
    def recursive_valid?(target, context, state)
      valid = state
      target.instance_variables.each do |ivar|
        ivar_value = target.instance_variable_get(ivar)
        if ivar_value.validatable?
          valid = valid && recursive_valid?(ivar_value, context, valid)
        elsif ivar_value.respond_to?(:each)
          ivar_value.each do |item|
            if item.validatable?
              valid = valid && recursive_valid?(item, context, valid)
            end
          end
        end
      end
      return valid && target.valid?
    end


    def validation_property_value(name)
      self.respond_to?(name, true) ? self.send(name) : nil
    end

    # Get the corresponding Object property, if it exists.
    def validation_property(field_name)
      properties.find{|p| p.name == field_name}
    end

    module ClassMethods
      include CouchRest::Validation::ValidatesPresent
      include CouchRest::Validation::ValidatesAbsent
      include CouchRest::Validation::ValidatesIsConfirmed
      # include CouchRest::Validation::ValidatesIsPrimitive
      # include CouchRest::Validation::ValidatesIsAccepted
      include CouchRest::Validation::ValidatesFormat
      include CouchRest::Validation::ValidatesLength
      # include CouchRest::Validation::ValidatesWithin
      include CouchRest::Validation::ValidatesIsNumber
      include CouchRest::Validation::ValidatesWithMethod
      # include CouchRest::Validation::ValidatesWithBlock
      # include CouchRest::Validation::ValidatesIsUnique
      include CouchRest::Validation::AutoValidate
      
      # Return the set of contextual validators or create a new one
      #
      def validators
        @validations ||= ContextualValidators.new
      end
      
      # Clean up the argument list and return a opts hash, including the
      # merging of any default opts. Set the context to default if none is
      # provided. Also allow :context to be aliased to :on, :when & group
      #
      def opts_from_validator_args(args, defaults = nil)
        opts = args.last.kind_of?(Hash) ? args.pop : {}
        context = :default
        context = opts[:context] if opts.has_key?(:context)
        context = opts.delete(:on) if opts.has_key?(:on)
        context = opts.delete(:when) if opts.has_key?(:when)
        context = opts.delete(:group) if opts.has_key?(:group)
        opts[:context] = context
        opts.merge!(defaults) unless defaults.nil?
        opts
      end
      
      # Given a new context create an instance method of
      # valid_for_<context>? which simply calls valid?(context)
      # if it does not already exist
      #
      def create_context_instance_methods(context)
        name = "valid_for_#{context.to_s}?"           # valid_for_signup?
        if !self.instance_methods.include?(name)
          class_eval <<-EOS, __FILE__, __LINE__
            def #{name}                               # def valid_for_signup?
              valid?('#{context.to_s}'.to_sym)        #   valid?('signup'.to_sym)
            end                                       # end
          EOS
        end

        all = "all_valid_for_#{context.to_s}?"        # all_valid_for_signup?
        if !self.instance_methods.include?(all)
          class_eval <<-EOS, __FILE__, __LINE__
            def #{all}                                # def all_valid_for_signup?
              all_valid?('#{context.to_s}'.to_sym)    #   all_valid?('signup'.to_sym)
            end                                       # end
          EOS
        end
      end

      # Create a new validator of the given klazz and push it onto the
      # requested context for each of the attributes in the fields list
      #
      def add_validator_to_context(opts, fields, klazz)
        fields.each do |field|
          validator = klazz.new(field.to_sym, opts)
          if opts[:context].is_a?(Symbol)
            unless validators.context(opts[:context]).include?(validator)
              validators.context(opts[:context]) << validator
              create_context_instance_methods(opts[:context])
            end
          elsif opts[:context].is_a?(Array)
            opts[:context].each do |c|
              unless validators.context(c).include?(validator)
                validators.context(c) << validator
                create_context_instance_methods(c)
              end
            end
          end
        end
      end
      
    end # module ClassMethods
  end # module Validation

end # module CouchRest
