# frozen_string_literal: true

class Serega
  #
  # Stores LazyLoader
  #
  class LazyLoader
    #
    # LazyLoader instance methods
    #
    module LazyInstanceMethods
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
        @name = name
        @block = prepare_block(block)
      end

      private

      def prepare_block(callable)
        if keyword_param?(callable, :ctx)
          callable
        else
          proc { |obj, ctx:| callable.call(obj) }
        end
      end

      def keyword_param?(callable, param_name)
        params = callable.parameters

        params.include?([:keyreq, param_name]) ||
          params.include?([:key, param_name]) ||
          params.include?([:keyrest, param_name])
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include LazyLoaderInstanceMethods
  end
end
