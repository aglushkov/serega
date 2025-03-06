# frozen_string_literal: true

class Serega
  #
  # Stores crutch
  #
  class SeregaCrutch
    #
    # Crutch instance methods
    #
    module CrutchInstanceMethods
      # Crutch block
      # @return [#call] Crutch block
      attr_reader :block

      #
      # Initializes new Crutch
      #
      # @param block [#call] Custom block to find Crutch value
      #
      def initialize(block)
        serializer_class = self.class.serializer_class
        serializer_class::CheckCrutchParams.new(name, opts, block).validate

        @initials = SeregaUtils::EnumDeepFreeze.call(
          name: name,
          opts: SeregaUtils::EnumDeepDup.call(opts),
          block: block
        )

        normalizer = serializer_class::SeregaCrutchNormalizer.new(initials)
        set_normalized_vars(normalizer)
      end

      # Shows whether Crutch has specified serializer
      # @return [Boolean] Checks if Crutch is relationship (if :serializer option exists)
      def relation?
        !@serializer.nil?
      end

      # Shows specified serializer class
      # @return [Serega, nil] Crutch serializer if exists
      def serializer
        serializer = @serializer
        return serializer if (serializer.is_a?(Class) && (serializer < Serega)) || !serializer

        @serializer = serializer.is_a?(String) ? Object.const_get(serializer, false) : serializer.call
      end

      #
      # Finds Crutch value
      #
      # @param object [Object] Serialized object
      # @param context [Hash, nil] Serialization context
      #
      # @return [Object] Serialized Crutch value
      #
      def value(object, context)
        value_block.call(object, context)
      end

      #
      # Checks if Crutch must be added to serialized response
      #
      # @param modifiers [Hash] Serialization modifiers
      # @option modifiers [Hash] :only The only Crutchs to serialize
      # @option modifiers [Hash] :except Crutchs to hide
      # @option modifiers [Hash] :with Hidden Crutchs to serialize additionally
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
        @many = normalizer.many
        @default = normalizer.default
        @value_block = normalizer.value_block
        @hide = normalizer.hide
        @serializer = normalizer.serializer
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include CrutchInstanceMethods
  end
end
