# frozen_string_literal: true

class Serega
  #
  # Low-level class that is used by more high-level SeregaSerializer
  # to construct serialized to hash response
  #
  class SeregaObjectSerializer
    #
    # SeregaObjectSerializer instance methods
    #
    module InstanceMethods
      attr_reader :context, :points, :many, :opts

      # @param context [Hash] Serialization context
      # @param many [TrueClass|FalseClass] is object is enumerable
      # @param points [Array<MapPoint>] Serialization points (attributes)
      #
      # @return [SeregaObjectSerializer] New SeregaObjectSerializer
      def initialize(context:, points:, many: nil, **opts)
        @context = context
        @points = points
        @many = many
        @opts = opts
      end

      # Serializes object(s)
      #
      # @param object [Object] Serialized object
      #
      # @return [Hash, Array<Hash>] Serialized object(s)
      def serialize(object)
        array?(object, many) ? serialize_array(object) : serialize_object(object)
      end

      private

      def serialize_array(object)
        object.map { |obj| serialize_object(obj) }
      end

      def serialize_object(object)
        return unless object

        points.each_with_object({}) do |point, container|
          attach_value(object, point, container)
        end
      end

      def attach_value(object, point, container)
        value = point.value(object, context)
        final_value = final_value(value, point)
        attach_final_value(final_value, point, container)
      end

      def attach_final_value(final_value, point, container)
        container[point.name] = final_value
      end

      def final_value(value, point)
        point.has_nested_points? ? relation_value(value, point) : value
      end

      def relation_value(value, point)
        nested_points = point.nested_points
        nested_serializer = point.nested_object_serializer
        nested_many = point.many
        serializer = nested_serializer.new(context: context, points: nested_points, many: nested_many, **opts)
        serializer.serialize(value)
      end

      def array?(object, many)
        many.nil? ? object.is_a?(Enumerable) : many
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
