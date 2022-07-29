# frozen_string_literal: true

class Serega
  class Convert
    module ConvertClassMethods
      def call(object, **opts)
        new(object, **opts).to_h
      end
    end

    module ConvertInstanceMethods
      attr_reader :object, :opts

      def initialize(object, **opts)
        @object = object
        @opts = opts
      end

      def to_h
        many? ? many(object) : one(object) || {}
      end

      private

      def many(objects)
        objects.map { |obj| one(obj) }
      end

      def one(object)
        self.class.serializer_class::ConvertItem.call(object, opts[:context], opts[:map])
      end

      def many?
        many = opts[:many]
        return many unless many.nil?

        object.is_a?(Enumerable)
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    extend ConvertClassMethods
    include ConvertInstanceMethods
  end
end
