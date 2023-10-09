# frozen_string_literal: true

class Serega
  #
  # Stores serialized attribute data
  #
  class SeregaAttribute
    #
    # Attribute instance methods
    #
    module AttributeInstanceMethods
      # Attribute initial params
      # @return [Hash] Attribute initial params
      attr_reader :initials

      # Attribute name
      # @return [Symbol] Attribute name
      attr_reader :name

      # Attribute :many option
      # @return [Boolean, nil] Attribute :many option
      attr_reader :many

      # Attribute :hide option
      # @return [Boolean, nil] Attribute :hide option
      attr_reader :hide

      #
      # Initializes new attribute
      #
      # @param name [Symbol, String] Name of attribute
      # @param opts [Hash] Attribute options
      # @option opts [Symbol] :key Object method name to fetch attribute value
      # @option opts [Hash] :delegate Allows to fetch value from nested object
      # @option opts [Boolean] :hide Specify `true` to not serialize this attribute by default
      # @option opts [Boolean] :many Specifies has_many relationship. By default is detected via object.is_a?(Enumerable)
      # @option opts [Proc, #call] :value Custom block or callable to find attribute value
      # @option opts [Serega, Proc] :serializer Relationship serializer class. Use `proc { MySerializer }` if serializers have cross references
      # @param block [Proc] Custom block to find attribute value
      #
      def initialize(name:, opts: {}, block: nil)
        serializer_class = self.class.serializer_class
        serializer_class::CheckAttributeParams.new(name, opts, block).validate

        @initials = SeregaUtils::EnumDeepFreeze.call(
          name: name,
          opts: SeregaUtils::EnumDeepDup.call(opts),
          block: block
        )

        normalizer = serializer_class::SeregaAttributeNormalizer.new(initials)
        set_normalized_vars(normalizer)
      end

      # Shows whether attribute has specified serializer
      # @return [Boolean] Checks if attribute is relationship (if :serializer option exists)
      def relation?
        !@serializer.nil?
      end

      # Shows specified serializer class
      # @return [Serega, nil] Attribute serializer if exists
      def serializer
        ser = @serializer
        return ser if (ser.is_a?(Class) && (ser < Serega)) || !ser

        @serializer = ser.is_a?(String) ? Object.const_get(ser, false) : ser.call
      end

      #
      # Finds attribute value
      #
      # @param object [Object] Serialized object
      # @param context [Hash, nil] Serialization context
      #
      # @return [Object] Serialized attribute value
      #
      def value(object, context)
        value_block.call(object, context)
      end

      #
      # Checks if attribute must be added to serialized response
      #
      # @param modifiers [Hash] Serialization modifiers
      # @option modifiers [Hash] :only The only attributes to serialize
      # @option modifiers [Hash] :except Attributes to hide
      # @option modifiers [Hash] :with Hidden attributes to serialize additionally
      #
      # @return [Boolean]
      #
      def visible?(modifiers)
        except = modifiers[:except] || FROZEN_EMPTY_HASH
        only = modifiers[:only] || FROZEN_EMPTY_HASH
        with = modifiers[:with] || FROZEN_EMPTY_HASH

        return false if except.member?(name) && except[name].empty?
        return true if only.member?(name)
        return true if with.member?(name)
        return false unless only.empty?

        !hide
      end

      private

      attr_reader :value_block

      def set_normalized_vars(normalizer)
        @name = normalizer.name
        @value_block = normalizer.value_block
        @hide = normalizer.hide
        @many = normalizer.many
        @serializer = normalizer.serializer
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include AttributeInstanceMethods
  end
end
