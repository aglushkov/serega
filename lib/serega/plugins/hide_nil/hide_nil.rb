# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin adds `:hide_nil` option to attributes to delete them from final result
    # if value is nil
    #
    module HideNil
      # @return [Symbol] Plugin name
      def self.plugin_name
        :hide_nil
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::SeregaObjectSerializer.include(SeregaObjectSerializerInstanceMethods)
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.config.attribute_keys << :hide_nil
      end

      #
      # Serega::SeregaAttribute additional/patched instance methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module AttributeInstanceMethods
        # Check hide_nil is specified
        def hide_nil?
          !!opts[:hide_nil]
        end
      end

      #
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super
          CheckOptHideNil.call(opts)
        end
      end

      #
      # Validator class for :hide_nil attribute option
      #
      class CheckOptHideNil
        #
        # Checks attribute :hide_nil option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Serega::SeregaError] SeregaError that option has invalid value
        #
        # @return [void]
        #
        def self.call(opts)
          return unless opts.key?(:hide_nil)

          value = opts[:hide_nil]
          return if (value == true) || (value == false)

          raise SeregaError, "Invalid option :hide_nil => #{value.inspect}. Must have a boolean value"
        end
      end

      #
      # SeregaObjectSerializer additional/patched class methods
      #
      # @see Serega::SeregaObjectSerializer
      #
      module SeregaObjectSerializerInstanceMethods
        private

        def attach_final_value(final_value, *)
          super unless final_value.nil?
        end
      end
    end

    register_plugin(HideNil.plugin_name, HideNil)
  end
end
