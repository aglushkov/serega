# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Formatters
      # @return [Symbol] Plugin name
      def self.plugin_name
        :formatters
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        if serializer_class.plugin_used?(:batch)
          raise SeregaError, "Plugin `formatters` must be loaded before `batch`"
        end
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
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
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
          @formatters ||= FormattersConfig.new(opts.fetch(:formatters))
        end
      end

      module AttributeInstanceMethods
        def formatter
          return @formatter if instance_variable_defined?(:@formatter)

          @formatter = formatter_resolved
        end

        def formatter_resolved
          formatter = opts[:format]
          return unless formatter

          formatter = self.class.serializer_class.config.formatters.opts.fetch(formatter) if formatter.is_a?(Symbol)
          formatter
        end

        def value_block
          return @value_block if instance_variable_defined?(:@value_block)
          return @value_block = super unless formatter

          new_value_block = formatted_block(formatter, super)

          # Format :const value in advance
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
            formatter.call(value)
          end
        end
      end
    end

    register_plugin(Formatters.plugin_name, Formatters)
  end
end
