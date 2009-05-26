# Ported from dm-migrations
require File.join(File.dirname(__FILE__), '..', 'support', 'class')

module CouchRest
  
  class Property
    # flag letting us know if we already checked the autovalidation settings
    attr_accessor :autovalidation_check
    @autovalidation_check = false
  end

  module Validation
    module AutoValidate      
      
      # # Force the auto validation for the class properties
      # # This feature is still not fully ported over,
      # # test are lacking, so please use with caution
      # def auto_validate!
      #   require 'ruby-debug'
      #   debugger
      #   auto_validation = true
      # end
      
      # adds message for validator
      def options_with_message(base_options, property, validator_name)
        options = base_options.clone
        opts = property.options
        options[:message] = if opts[:messages]
          if opts[:messages].is_a?(Hash) and msg = opts[:messages][validator_name]
            msg
          else
            nil
          end
        elsif opts[:message]
          opts[:message]
        else
          nil
        end
        options
      end

      
      ##
      # Auto-generate validations for a given property. This will only occur
      # if the option :auto_validation is either true or left undefined.
      #
      # @details [Triggers]
      #   Triggers that generate validator creation
      #
      #   :nullable => false
      #       Setting the option :nullable to false causes a
      #       validates_presence_of validator to be automatically created on
      #       the property
      #
      #   :size => 20 or :length => 20
      #       Setting the option :size or :length causes a validates_length_of
      #       validator to be automatically created on the property. If the
      #       value is a Integer the validation will set :maximum => value if
      #       the value is a Range the validation will set :within => value
      #
      #   :format => :predefined / lambda / Proc
      #       Setting the :format option causes a validates_format_of
      #       validator to be automatically created on the property
      #
      #   :set => ["foo", "bar", "baz"]
      #       Setting the :set option causes a validates_within
      #       validator to be automatically created on the property
      #
      #   Integer type
      #       Using a Integer type causes a validates_is_number
      #       validator to be created for the property.  integer_only
      #       is set to true
      #
      #   Float type
      #       Using a Integer type causes a validates_is_number
      #       validator to be created for the property.  integer_only
      #       is set to false, and precision/scale match the property
      #
      #
      #   Messages
      #
      #   :messages => {..}
      #       Setting :messages hash replaces standard error messages
      #       with custom ones. For instance:
      #       :messages => {:presence => "Field is required",
      #                     :format => "Field has invalid format"}
      #       Hash keys are: :presence, :format, :length, :is_unique,
      #                      :is_number, :is_primitive
      #
      #   :message => "Some message"
      #       It is just shortcut if only one validation option is set
      #
      def auto_generate_validations(property)
        return unless ((property.autovalidation_check != true) && self.auto_validation)
        return if (property.options && (property.options.has_key?(:auto_validation) && !property.options[:auto_validation]) || property.read_only)
        # value is set by the storage system
        opts = {}
        opts[:context] = property.options[:validates] if property.options.has_key?(:validates)

        # presence
        if opts[:allow_nil] == false
          # validates_present property.name, opts
          validates_present property.name, options_with_message(opts, property, :presence)
        end

        # length
        if property.type == "String"
          # XXX: maybe length should always return a Range, with the min defaulting to 1
          # 52 being the max set 
          len = property.options.fetch(:length, property.options.fetch(:size, 52))
          if len.is_a?(Range)
            opts[:within] = len
          else
            opts[:maximum] = len
          end
          # validates_length property.name, opts
          validates_length property.name, options_with_message(opts, property, :length)
        end

        # format
        if property.options.has_key?(:format)
          opts[:with] = property.options[:format]
          # validates_format property.name, opts
          validates_format property.name, options_with_message(opts, property, :format)
        end

        # uniqueness validator
        if property.options.has_key?(:unique)
          value = property.options[:unique]
          if value.is_a?(Array) || value.is_a?(Symbol)
            # validates_is_unique property.name, :scope => Array(value)
            validates_is_unique property.name, options_with_message({:scope => Array(value)}, property, :is_unique)
          elsif value.is_a?(TrueClass)
            # validates_is_unique property.name
            validates_is_unique property.name, options_with_message({}, property, :is_unique)
          end
        end

        # within validator
        if property.options.has_key?(:set)
          validates_within property.name, options_with_message({:set => property.options[:set]}, property, :within)
        end

        # numeric validator
        if "Integer" == property.type
          opts[:integer_only] = true
          # validates_is_number property.name, opts
          validates_is_number property.name, options_with_message(opts, property, :is_number)
        elsif Float == property.type
          opts[:precision] = property.precision
          opts[:scale]     = property.scale
          # validates_is_number property.name, opts
          validates_is_number property.name, options_with_message(opts, property, :is_number)
        end
        
        # marked the property has checked
        property.autovalidation_check = true
        
      end

    end # module AutoValidate
  end # module Validation
end # module CouchRest
