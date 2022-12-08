# frozen_string_literal: true

class Serega
  #
  # Combines attribute and nested attributes
  #
  class SeregaMapPoint
    #
    # SeregaMapPoint instance methods
    #
    module InstanceMethods
      extend Forwardable

      # Shows current attribute
      # @return [Serega::SeregaAttribute] Current attribute
      attr_reader :attribute

      # Shows nested points
      # @return [NilClass, Array<Serega::SeregaMapPoint>] Nested points or nil
      attr_reader :nested_points

      # @!method name
      #   Attribute `name`
      #   @see Serega::SeregaAttribute::AttributeInstanceMethods#name
      # @!method value
      #   Attribute `value` block
      #   @see Serega::SeregaAttribute::AttributeInstanceMethods#value
      # @!method many
      #   Attribute `many` option
      #   @see Serega::SeregaAttribute::AttributeInstanceMethods#many
      def_delegators :@attribute, :name, :value, :many

      #
      # Initializes map point
      #
      # @param attribute [Serega::SeregaAttribute] Attribute to construct map point
      # @param nested_points [NilClass, Array<Serega::SeregaMapPoint>] Nested map points for provided attribute
      #
      # @return [Serega::SeregaMapPoint] New map point
      #
      def initialize(attribute, nested_points)
        @attribute = attribute
        @nested_points = nested_points
      end

      #
      # Checks if attribute has nested points (is a link to another serializer)
      #
      # @return [Boolean] whether attribute has nested points
      #
      def has_nested_points?
        !nested_points.nil?
      end

      #
      # @return [Serega::SeregaObjectSerializer] object serializer for nested points
      #
      def nested_object_serializer
        attribute.serializer::SeregaObjectSerializer
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
