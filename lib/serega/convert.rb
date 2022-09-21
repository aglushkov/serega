# frozen_string_literal: true

class Serega
  class SeregaConvert
    module SeregaConvertClassMethods
      def call(object, **opts)
        new(object, **opts).to_h
      end
    end

    module SeregaConvertInstanceMethods
      attr_reader :object, :context, :opts

      def initialize(object, **opts)
        @object = object
        @opts = opts
        @context = opts[:context] ||= {}
      end

      def to_h
        many? ? many(object) : one(object) || {}
      end

      private

      def many(objects)
        objects.map.with_index do |obj, index|
          with_context_path(index) { one(obj) }
        end
      end

      def one(object)
        self.class.serializer_class::SeregaConvertItem.call(object, context, opts[:map])
      end

      def many?
        many = opts[:many]
        return many unless many.nil?

        object.is_a?(Enumerable)
      end

      def with_context_path(path)
        paths = context[:_path] ||= []
        paths << path
        result = yield
        paths.pop
        result
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    extend SeregaConvertClassMethods
    include SeregaConvertInstanceMethods
  end
end
