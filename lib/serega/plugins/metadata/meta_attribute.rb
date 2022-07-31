# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      #
      # Stores Attribute data
      #
      class MetaAttribute
        #
        # Stores Attribute instance methods
        #
        module InstanceMethods
          # @return [Symbol] Meta attribute name
          attr_reader :name

          # @return [Symbol] Meta attribute full path
          attr_reader :path

          # @return [Proc] Meta attribute options
          attr_reader :opts

          # @return [Proc] Meta attribute originally added block
          attr_reader :block

          #
          # Initializes new meta attribute
          #
          # @param path [Array<Symbol, String>] Path for metadata of attribute
          #
          # @param opts [Hash] metadata attribute options
          #
          # @param block [Proc] Proc that receives object(s) and context and finds value
          #
          def initialize(path:, opts:, block:)
            check(path, opts, block)

            @name = path.join(".").to_sym
            @path = SeregaUtils::EnumDeepDup.call(path)
            @opts = SeregaUtils::EnumDeepDup.call(opts)
            @block = block
          end

          #
          # Finds attribute value
          #
          # @param object [Object] Serialized object(s)
          # @param context [Hash, nil] Serialization context
          #
          # @return [Object] Serialized meta attribute value
          #
          def value(object, context)
            block.call(object, context)
          end

          def hide?(value)
            (opts[:hide_nil] && value.nil?) || (opts[:hide_empty] && value.empty?)
          end

          private

          def check(path, opts, block)
            CheckPath.call(path)
            CheckOpts.call(opts, self.class.serializer_class.config[:metadata][:attribute_keys])
            CheckBlock.call(block)
          end
        end

        extend Serega::SeregaHelpers::SerializerClassHelper
        include InstanceMethods
      end
    end
  end
end
