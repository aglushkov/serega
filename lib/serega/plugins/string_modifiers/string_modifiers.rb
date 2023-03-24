# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module StringModifiers
      # @return [Symbol] Plugin name
      def self.plugin_name
        :string_modifiers
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
        serializer_class.include(InstanceMethods)
        require_relative "./parse_string_modifiers"
      end

      #
      # Serega additional/patched instance methods
      #
      # @see Serega
      #
      module InstanceMethods
        private

        def parse_modifier(value)
          return ParseStringModifiers.parse(value) if value.is_a?(String)

          super
        end
      end
    end

    register_plugin(StringModifiers.plugin_name, StringModifiers)
  end
end
