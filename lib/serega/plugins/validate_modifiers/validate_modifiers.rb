# frozen_string_literal: true

class Serega
  module Plugins
    module ValidateModifiers
      def self.plugin_name
        :validate_modifiers
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class::Map.extend(MapClassMethods)
        require_relative "./validate"
      end

      module MapClassMethods
        private

        def construct_map(serializer_class, only:, except:, with:)
          Validate.call(serializer_class, only)
          Validate.call(serializer_class, except)
          Validate.call(serializer_class, with)
          super
        end
      end
    end

    register_plugin(ValidateModifiers.plugin_name, ValidateModifiers)
  end
end
