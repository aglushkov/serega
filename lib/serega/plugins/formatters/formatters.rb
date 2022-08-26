# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Formatters
      def self.plugin_name
        :formatters
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        config.opts[:formatters] = {}
        config.formatters.add(opts[:formatters] || {})
        config.attribute_keys << :format
      end

      class FormattersConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def add(formatters)
          formatters.each_pair do |key, value|
            opts[key] = value
          end
        end
      end

      module ConfigInstanceMethods
        def formatters
          FormattersConfig.new(opts.fetch(:formatters))
        end
      end

      module AttributeInstanceMethods
        def value_block
          return @value_block if instance_variable_defined?(:@value_block)

          original_block = super
          formatter = opts[:format]
          return original_block unless formatter

          new_value_block = formatted_block(formatter, original_block)

          # Detect formatted :const value in advance
          if opts.key?(:const)
            const_value = new_value_block.call
            new_value_block = proc { const_value }
          end

          @value_block = new_value_block
        end

        private

        def formatted_block(formatter, original_block)
          proc do |object, context|
            value = original_block.call(object, context)

            if formatter.is_a?(Symbol)
              self.class.serializer_class.config.formatters.opts.fetch(formatter).call(value)
            else
              formatter.call(value)
            end
          end
        end
      end
    end

    register_plugin(Formatters.plugin_name, Formatters)
  end
end
