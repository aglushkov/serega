# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module StringModifiers
      def self.plugin_name
        :string_modifiers
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        require_relative "./parse_string_modifiers"
      end

      module InstanceMethods
        private

        def prepare_modifiers(opts)
          parsed_opts =
            opts.each_with_object({}) do |(key, value), obj|
              value = ParseStringModifiers.call(value) if (key == :only) || (key == :except) || (key == :with)
              obj[key] = value
            end

          super(parsed_opts)
        end
      end
    end

    register_plugin(StringModifiers.plugin_name, StringModifiers)
  end
end
