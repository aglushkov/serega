# frozen_string_literal: true

class Serega
  class SeregaMapPoint
    module InstanceMethods
      extend Forwardable

      attr_reader :attribute, :nested_points

      def_delegators :@attribute, :name, :value, :many

      def initialize(attribute, nested_points)
        @attribute = attribute
        @nested_points = nested_points
      end

      def has_nested_points?
        !nested_points.nil?
      end

      def nested_object_serializer
        attribute.serializer::SeregaObjectSerializer
      end

      # TODO: remove, we use this method in tests only
      def ==(other)
        (other.attribute == attribute) && (other.nested_points == nested_points)
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
