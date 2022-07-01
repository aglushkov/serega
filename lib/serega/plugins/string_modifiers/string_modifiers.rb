# frozen_string_literal: true

class Serega
  module Plugins
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
          opts = {
            only: ParseStringModifiers.call(opts[:only]),
            except: ParseStringModifiers.call(opts[:except]),
            with: ParseStringModifiers.call(opts[:with])
          }

          super
        end
      end
    end

    register_plugin(StringModifiers.plugin_name, StringModifiers)
  end
end
