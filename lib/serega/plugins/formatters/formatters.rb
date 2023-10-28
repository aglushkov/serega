# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin :formatters
    #
    # Allows to define value formatters one time and apply them on any attributes.
    #
    # Config option `config.formatters.add()` can be used to add formatters.
    #
    # Attribute option `:format` now can be used with name of formatter or with callable instance.
    #
    # @example
    #   class AppSerializer < Serega
    #     plugin :formatters, formatters: {
    #       iso8601: ->(value) { time.iso8601.round(6) },
    #       on_off: ->(value) { value ? 'ON' : 'OFF' },
    #       money: ->(value) { value.round(2) }
    #     }
    #   end
    #
    #   class UserSerializer < Serega
    #     # Additionally we can add formatters via config in subclasses
    #     config.formatters.add(
    #       iso8601: ->(value) { time.iso8601.round(6) },
    #       on_off: ->(value) { value ? 'ON' : 'OFF' },
    #       money: ->(value) { value.round(2) }
    #     )
    #
    #     # Using predefined formatter
    #     attribute :commission, format: :money
    #     attribute :is_logined, format: :on_off
    #     attribute :created_at, format: :iso8601
    #     attribute :updated_at, format: :iso8601
    #
    #     # Using `callable` formatter
    #     attribute :score_percent, format: proc { |percent| "#{percent.round(2)}%" }
    #   end
    #
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
        serializer_class::SeregaAttributeNormalizer.include(AttributeNormalizerInstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
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

      # Formatters plugin config
      class FormattersConfig
        attr_reader :opts

        #
        # Initializes formatters config object
        #
        # @param opts [Hash] options
        #
        # @return FormattersConfig
        def initialize(opts)
          @opts = opts
        end

        # Adds new formatters
        #
        # @param formatters [Hash<Symbol, #call>] hash key is a formatter name and
        #   hash value is a callable instance to format value
        #
        # @return [void]
        def add(formatters)
          formatters.each_pair do |key, value|
            CheckFormatter.call(key, value)
            opts[key] = value
          end
        end
      end

      #
      # Config class additional/patched instance methods
      #
      # @see SeregaConfig
      #
      module ConfigInstanceMethods
        # @return [SeregaPlugins::Formatters::FormattersConfig] current formatters config
        def formatters
          @formatters ||= FormattersConfig.new(opts.fetch(:formatters))
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

          CheckOptFormat.call(opts, self.class.serializer_class)
        end
      end

      #
      # Attribute class additional/patched instance methods
      #
      # @see SeregaAttributeNormalizer
      #
      module AttributeNormalizerInstanceMethods
        # Block or callable instance that will format attribute values
        # @return [Proc, #call, nil] Block or callable instance that will format attribute values
        def formatter
          return @formatter if instance_variable_defined?(:@formatter)

          @formatter = prepare_formatter
        end

        private

        def prepare_value_block
          return super unless formatter

          if init_opts.key?(:const)
            # Format const value in advance
            const_value = formatter.call(init_opts[:const])
            proc { const_value }
          else
            # Wrap original block into formatter block
            proc do |object, context|
              value = super.call(object, context)
              formatter.call(value)
            end
          end
        end

        def prepare_formatter
          formatter = init_opts[:format]
          return unless formatter

          if formatter.is_a?(Symbol)
            self.class.serializer_class.config.formatters.opts.fetch(formatter)
          else
            formatter # already callable
          end
        end
      end

      #
      # Validator for attribute :format option
      #
      class CheckOptFormat
        class << self
          #
          # Checks attribute :format option must be registered or valid callable with 1 arg
          #
          # @param opts [value] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts, serializer_class)
            return unless opts.key?(:format)

            formatter = opts[:format]

            if formatter.is_a?(Symbol)
              check_formatter_defined(serializer_class, formatter)
            else
              CheckFormatter.call(:format, formatter)
            end
          end

          private

          def check_formatter_defined(serializer_class, formatter)
            return if serializer_class.config.formatters.opts.key?(formatter)

            raise Serega::SeregaError, "Formatter `#{formatter.inspect}` was not defined"
          end
        end
      end

      #
      # Validator for formatters defined as config options or directly as attribute :format option
      #
      class CheckFormatter
        class << self
          #
          # Check formatter type and parameters
          #
          # @param formatter_name [Symbol] Name of formatter
          # @param formatter [#call] Formatter callable object
          #
          # @return [void]
          #
          def call(formatter_name, formatter)
            raise Serega::SeregaError, "Option #{formatter_name.inspect} must have callable value" unless formatter.respond_to?(:call)

            SeregaValidations::Utils::CheckExtraKeywordArg.call(formatter, "#{formatter_name.inspect} value")
            params_count = SeregaUtils::ParamsCount.call(formatter, max_count: 1)

            if params_count != 1
              raise SeregaError, "Formatter should have exactly 1 required parameter (value to format)"
            end
          end
        end
      end
    end

    register_plugin(Formatters.plugin_name, Formatters)
  end
end
