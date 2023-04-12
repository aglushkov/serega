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
      # Symbolized initial attribute name
      #
      # @return [Symbol] Attribute normalized name
      #
      def name
        @name ||= prepare_name
      end

      #
      # Symbolized initial attribute key or attribute name if key is empty
      #
      # @return [Symbol] Attribute normalized name
      #
      def key
        @key ||= prepare_key
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

      private

      def prepare_name
        init_name.to_sym
      end

      #
      # Patched in:
      # - plugin :formatters (wraps resulted block in formatter block and formats :const values)
      #
      def prepare_value_block
        init_block ||
          init_opts[:value] ||
          prepare_const_block ||
          prepare_delegate_block ||
          prepare_keyword_block
      end

      #
      # Patched in:
      # - plugin :preloads (returns true by default if config option auto_hide_attribute_with_preloads is enabled)
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

      def prepare_key
        key = init_opts[:key]
        key ? key.to_sym : name
      end

      def prepare_const_block
        return unless init_opts.key?(:const)

        const = init_opts[:const]
        proc { const }
      end

      def prepare_keyword_block
        key_method_name = key
        proc do |object|
          handle_no_method_error { object.public_send(key_method_name) }
        end
      end

      def prepare_delegate_block
        delegate = init_opts[:delegate]
        return unless delegate

        key_method_name = delegate[:key] || key
        delegate_to = delegate[:to]

        if delegate[:allow_nil]
          proc do |object|
            handle_no_method_error do
              object.public_send(delegate_to)&.public_send(key_method_name)
            end
          end
        else
          proc do |object|
            handle_no_method_error do
              object.public_send(delegate_to).public_send(key_method_name)
            end
          end
        end
      end

      def handle_no_method_error
        yield
      rescue NoMethodError => error
        raise error, "NoMethodError when serializing '#{name}' attribute in #{self.class.serializer_class}\n\n#{error.message}", error.backtrace
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include AttributeNormalizerInstanceMethods
  end
end
