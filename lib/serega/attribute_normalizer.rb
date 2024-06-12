# frozen_string_literal: true

class Serega
  #
  # Prepares provided attribute options
  #
  class SeregaAttributeNormalizer
    #
    # AttributeNormalizer instance methods
    #
    module AttributeNormalizerInstanceMethods
      # Attribute initial params
      # @return [Hash] Attribute initial params
      attr_reader :init_name, :init_opts, :init_block

      #
      # Instantiates attribute options normalizer
      #
      # @param initials [Hash] new attribute options
      #
      # @return [SeregaAttributeNormalizer] Instantiated attribute options normalizer
      #
      def initialize(initials)
        @init_name = initials[:name]
        @init_opts = initials[:opts]
        @init_block = initials[:block]
      end

      #
      # Stringified initial attribute name
      #
      # @return [String] Attribute normalized name
      #
      def name
        @name ||= prepare_name
      end

      #
      # Symbolized initial attribute name
      #
      # @return [Symbol] Attribute normalized name
      #
      def symbol_name
        @symbol_name ||= name.to_sym
      end

      #
      # Symbolized initial attribute method name
      #
      # @return [Symbol] Attribute normalized method name
      #
      def method_name
        @method_name ||= prepare_method_name
      end

      #
      # Combines all options to return single block that will be used to find
      # attribute value during serialization
      #
      # @return [#call] Attribute normalized callable value block
      #
      def value_block
        @value_block ||= prepare_value_block
      end

      #
      # Shows if attribute is specified to be hidden
      #
      # @return [Boolean, nil] if attribute must be hidden by default
      #
      def hide
        return @hide if instance_variable_defined?(:@hide)

        @hide = prepare_hide
      end

      #
      # Shows if attribute is specified to be a one-to-many relationship
      #
      # @return [Boolean, nil] if attribute is specified to be a one-to-many relationship
      #
      def many
        return @many if instance_variable_defined?(:@many)

        @many = prepare_many
      end

      #
      # Shows specified attribute serializer
      # @return [Serega, String, #callable, nil] specified serializer
      #
      def serializer
        return @serializer if instance_variable_defined?(:@serializer)

        @serializer = prepare_serializer
      end

      #
      # Shows the default attribute value. It is a value that replaces found nils.
      #
      # When custom :default is not specified, we set empty array as default when `many: true` specified
      #
      # @return [Object] Attribute default value
      #
      def default
        return @default if instance_variable_defined?(:@default)

        @default = prepare_default
      end

      private

      def prepare_name
        SeregaUtils::SymbolName.call(init_name)
      end

      #
      # Patched in:
      # - plugin :formatters (wraps resulted block in formatter block and formats :const values)
      #
      def prepare_value_block
        value_block =
          prepare_init_block ||
          prepare_value_option_block ||
          prepare_const_block ||
          prepare_delegate_block ||
          prepare_keyword_block

        prepare_value_block_with_default(value_block)
      end

      #
      # Patched in:
      # - plugin :preloads (returns true by default if config option auto_hide_attribute_with_preloads is enabled)
      # - plugin :batch (returns true by default if auto_hide option was set and attribute has batch loader)
      #
      def prepare_hide
        init_opts[:hide]
      end

      def prepare_many
        init_opts[:many]
      end

      def prepare_serializer
        init_opts[:serializer]
      end

      def prepare_method_name
        (init_opts[:method] || init_name).to_sym
      end

      def prepare_const_block
        return unless init_opts.key?(:const)

        const = init_opts[:const]
        proc { const }
      end

      def prepare_keyword_block
        key_method_name = method_name
        proc do |object|
          object.public_send(key_method_name)
        end
      end

      def prepare_init_block
        prepare_callable_proc(init_block)
      end

      def prepare_value_option_block
        prepare_callable_proc(init_opts[:value])
      end

      def prepare_callable_proc(callable)
        return unless callable

        params_count = SeregaUtils::ParamsCount.call(callable, max_count: 2)
        case params_count
        when 0 then proc { |obj, _ctx| callable.call }
        when 1 then proc { |obj, _ctx| callable.call(obj) }
        else callable
        end
      end

      def prepare_value_block_with_default(callable)
        default_value = default
        return callable if default_value.nil?

        proc { |obj, ctx|
          res = callable.call(obj, ctx)
          res.nil? ? default_value : res
        }
      end

      def prepare_default
        init_opts.fetch(:default) { many ? FROZEN_EMPTY_ARRAY : nil }
      end

      def prepare_delegate_block
        delegate = init_opts[:delegate]
        return unless delegate

        key_method_name = delegate[:method] || method_name
        delegate_to = delegate[:to]

        allow_nil = delegate.fetch(:allow_nil) { self.class.serializer_class.config.delegate_default_allow_nil }

        if allow_nil
          proc do |object|
            object.public_send(delegate_to)&.public_send(key_method_name)
          end
        else
          proc do |object|
            object.public_send(delegate_to).public_send(key_method_name)
          end
        end
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include AttributeNormalizerInstanceMethods
  end
end
