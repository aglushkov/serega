# frozen_string_literal: true

class Serega
  module Plugins
    #
    # Plugin adds `:hide_nil` option to attributes to delete them from final result
    # if value is nil
    #
    module HideNil
      # @return [Symbol] plugin name
      def self.plugin_name
        :hide_nil
      end

      #
      # Includes plugin modules to current serializer
      #
      # @param serializer_class [Class] current serializer class
      # @param _opts [Hash] plugin opts
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class::Attribute.include(AttributeMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::ConvertItem.extend(ConvertItemClassMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.config[:attribute_keys] << :hide_nil
      end

      # Adds #hide_nil? Attribute instance method
      module AttributeMethods
        def hide_nil?
          !!opts[:hide_nil]
        end
      end

      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super
          CheckOptHideNil.call(opts)
        end
      end

      class CheckOptHideNil
        #
        # Checks attribute :hide_nil option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Serega::Error] Error that option has invalid value
        #
        # @return [void]
        #
        def self.call(opts)
          return unless opts.key?(:hide_nil)

          value = opts[:hide_nil]
          return if (value == true) || (value == false)

          raise Error, "Invalid option :hide_nil => #{value.inspect}. Must have a boolean value"
        end
      end

      module ConvertItemClassMethods
        private

        def attach_value(value, *args)
          super unless value.nil?
        end
      end
    end

    register_plugin(HideNil.plugin_name, HideNil)
  end
end
