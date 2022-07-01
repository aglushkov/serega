# frozen_string_literal: true

class Serega
  module Plugins
    module ValidateModifiers
      def self.plugin_name
        :validate_modifiers
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        require_relative "./validate"
      end

      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.config[:validate_modifiers] = {auto: opts.fetch(:auto, true)}
      end

      module InstanceMethods
        # Raises error if some modifiers are invalid
        def validate_modifiers
          @modifiers_validated ||= begin
            Validate.call(self.class, opts[:only])
            Validate.call(self.class, opts[:except])
            Validate.call(self.class, opts[:with])
            true
          end
        end

        private

        def initialize(opts)
          super
          validate_modifiers if self.class.config[:validate_modifiers][:auto]
        end
      end

      module InstanceMethods
      end
    end

    register_plugin(ValidateModifiers.plugin_name, ValidateModifiers)
  end
end
