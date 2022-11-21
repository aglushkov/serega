# frozen_string_literal: true

class Serega
  class SeregaSerializer
    module SeregaSerializerInstanceMethods
      # @param context [Hash] Serialization context
      # @param many [TrueClass|FalseClass] is object is enumerable
      # @param points [Array<MapPoint>] Serialization points (attributes)
      # @param opts [Hash] Any custom options
      def initialize(context:, points:, many: nil, **opts)
        @context = context
        @points = points
        @many = many
        @opts = opts
      end

      # @param object [Object] Serialized object
      def serialize(object)
        self.class.serializer_class::SeregaObjectSerializer
          .new(context: context, points: points, many: many, **opts)
          .serialize(object)
      end

      private

      attr_reader :context, :points, :many, :opts
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include SeregaSerializerInstanceMethods
  end
end
