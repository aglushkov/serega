# frozen_string_literal: true

class Serega
  class SeregaConvert
    module SeregaConvertClassMethods
      def call(object, context, map)
        new(object, context, map).to_h
      end
    end

    module SeregaConvertInstanceMethods
      attr_reader :object, :context, :serializer_class, :map

      def initialize(object, context, map)
        @object = object
        @context = context
        @map = map
        @serializer_class = self.class.serializer_class
      end

      def to_h
        many? ? many(object) : one(object) || {}
      end

      private

      def many(objects)
        objects.map { |obj| one(obj) }
      end

      def one(object)
        serializer_class::SeregaConvertItem.call(object, context, map)
      end

      def many?
        return @many if defined?(@many)

        many = context[:many]
        @many = many.nil? ? object.is_a?(Enumerable) : many
      end
    end

    extend Serega::SeregaHelpers::SeregaSerializerClassHelper
    extend SeregaConvertClassMethods
    include SeregaConvertInstanceMethods
  end
end
