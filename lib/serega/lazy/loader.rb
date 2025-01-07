# frozen_string_literal: true

class Serega
  #
  # Lazy feature main module
  #
  module SeregaLazy
    #
    #  Lazy loader
    #
    class Loader
      #
      # LazyLoader instance methods
      #
      module InstanceMethods
        # LazyLoader initial params
        # @return [Hash] LazyLoader initial params
        attr_reader :initials

        # LazyLoader name
        # @return [Symbol] LazyLoader name
        attr_reader :name

        # LazyLoader block
        # @return [#call] LazyLoader block
        attr_reader :block

        #
        # Initializes new lazy loader
        #
        # @param name [Symbol, String] Name of attribute
        # @param block [#call] LazyLoader block
        #
        def initialize(name:, block:)
          serializer_class = self.class.serializer_class
          serializer_class::CheckLazyLoaderParams.new(name, block).validate

          @initials = SeregaUtils::EnumDeepFreeze.call(name: name, block: block)
          @name = name.to_sym
          @block = block
          @signature = SeregaUtils::MethodSignature.call(block, pos_limit: 2, keyword_args: [:ctx])
        end

        def load(objects, context)
          case signature
          when "1" then block.call(objects)
          when "2" then block.call(objects, context)
          else block.call(objects, ctx: context) # "1_ctx"
          end
        end

        private

        # LazyLoader block signature
        # @return [String] LazyLoader block signature
        attr_reader :signature
      end

      extend SeregaHelpers::SerializerClassHelper
      include InstanceMethods
    end
  end
end
