# frozen_string_literal: true

class Serega
  #
  # Stores Attribute data
  #
  class SeregaAttribute
    #
    # Stores Attribute instance methods
    #
    module AttributeInstanceMethods
      # @return [Symbol] Attribute name
      attr_reader :name

      # @return [Hash] Attribute options
      attr_reader :opts

      # @return [Proc] Attribute originally added block
      attr_reader :block

      #
      # Initializes new attribute
      #
      # @param name [Symbol, String] Name of attribute
      #
      # @param opts [Hash] Attribute options
      # @option opts [Symbol] :key Object instance method name to get attribute value
      # @option opts [Boolean] :exposed Configures if we should serialize this attribute by default.
      #  (by default is true for regular attributes and false for relationships)
      # @option opts [Boolean] :many Specifies has_many relationship. By default is detected via object.is_a?(Enumerable)
      # @option opts [Serega, Proc] :serializer Relationship serializer class. Use `proc { MySerializer }` if serializers have cross references.
      #
      # @param block [Proc] Proc that receives object and context and finds attribute value
      #
      def initialize(name:, opts: {}, block: nil)
        self.class.serializer_class::CheckAttributeParams.new(name, opts, block).validate

        @name = name.to_sym
        @opts = SeregaUtils::EnumDeepDup.call(opts)
        @block = block
      end

      # @return [Symbol] Object method name to will be used to get attribute value unless block provided
      def key
        @key ||= opts.key?(:key) ? opts[:key].to_sym : name
      end

      # @return [Boolean, nil] Attribute initial :hide option value
      def hide
        opts[:hide]
      end

      # @return [Boolean, nil] Attribute initialization :many option
      def many
        opts[:many]
      end

      # @return [Boolean] Checks if attribute is relationship (if :serializer option exists)
      def relation?
        !opts[:serializer].nil?
      end

      # @return [Serega, nil] Attribute serializer if exists
      def serializer
        return @serializer if instance_variable_defined?(:@serializer)

        serializer = opts[:serializer]
        @serializer =
          case serializer
          when String then Object.const_get(serializer, false)
          when Proc then serializer.call
          else serializer
          end
      end

      # @return [Proc] Proc to find attribute value
      def value_block
        return @value_block if instance_variable_defined?(:@value_block)

        @value_block =
          block ||
          opts[:value] ||
          const_block ||
          delegate_block ||
          keyword_block
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
      # @param except [Hash] manually hidden attributes
      # @param only [Hash] manually enforced exposed attributes, other attributes are enforced to be hidden
      # @param with [Hash] manually enforced exposed attributes
      #
      # @return [Boolean]
      #
      def visible?(except:, only:, with:)
        return false if except.member?(name) && except[name].empty?
        return true if only.member?(name)
        return true if with.member?(name)
        return false unless only.empty?

        !hide
      end

      private

      def const_block
        return unless opts.key?(:const)

        const = opts[:const]
        proc { const }
      end

      def keyword_block
        key_method_name = key
        proc { |object| object.public_send(key_method_name) }
      end

      def delegate_block
        return unless opts.key?(:delegate)

        key_method_name = key
        delegate_to = opts[:delegate][:to]

        if opts[:delegate][:allow_nil]
          proc { |object| object.public_send(delegate_to)&.public_send(key_method_name) }
        else
          proc { |object| object.public_send(delegate_to).public_send(key_method_name) }
        end
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include AttributeInstanceMethods
  end
end
