# frozen_string_literal: true

class Serega
  class SeregaSerializer
    module SeregaSerializerInstanceMethods
      # @param serializer [Serega] Current serializer
      # @param context [Hash] Serialization context
      # @param many [Boolean] whether you will provide multiple objects to serialize
      # @param opts [Hash] Any custom options
      def initialize(serializer:, context:, many: nil, **opts)
        @serializer = serializer
        @context = context
        @many = many
        @opts = opts
        @points = serializer.map
      end

      #
      # Serializes object to Hash or to Array of Hashes.
      #
      # @param object [Object] object(s) to serialize
      #
      # @return [Hash, Array<Hash>] Serialized object(s)
      #
      def serialize(object)
        serializer.class::SeregaObjectSerializer
          .new(context: context, points: points, many: many, **opts)
          .serialize(object)
      end

      private

      attr_reader :serializer, :context, :points, :many, :opts
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include SeregaSerializerInstanceMethods
  end
end
