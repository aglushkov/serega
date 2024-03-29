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

          # @return [Proc,nil] Meta attribute originally added block
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
            @normalized_block = normalize_block(opts[:value], opts[:const], block)
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
            normalized_block.call(object, context)
          end

          def hide?(value)
            (!!opts[:hide_nil] && value.nil?) || (!!opts[:hide_empty] && (value.nil? || (value.respond_to?(:empty?) && value.empty?)))
          end

          private

          attr_reader :normalized_block

          def normalize_block(value, const, block)
            return proc { const } if const

            callable = value || block
            params_count = SeregaUtils::ParamsCount.call(callable, max_count: 2)

            case params_count
            when 0 then proc { callable.call }
            when 1 then proc { |obj| callable.call(obj) }
            else callable
            end
          end

          def check(path, opts, block)
            CheckPath.call(path) if check_attribute_name
            CheckOpts.call(opts, block, attribute_keys)
            CheckBlock.call(block) if block
          end

          def attribute_keys
            self.class.serializer_class.config.metadata.attribute_keys
          end

          def check_attribute_name
            self.class.serializer_class.config.check_attribute_name
          end
        end

        extend Serega::SeregaHelpers::SerializerClassHelper
        include InstanceMethods
      end
    end
  end
end
