# frozen_string_literal: true

class Serega
  #
  # Combines attribute and nested attributes
  #
  class SeregaPlanPoint
    #
    # SeregaPlanPoint instance methods
    #
    module InstanceMethods
      extend Forwardable

      # Link to current plan this point belongs to
      # @return [SeregaAttribute] Current plan
      attr_reader :plan

      # Shows current attribute
      # @return [SeregaAttribute] Current attribute
      attr_reader :attribute

      # Shows child plan if exists
      # @return [SeregaPlan, nil] Attribute serialization plan
      attr_reader :child_plan

      # Child fields to serialize
      # @return [Hash] Attributes to serialize
      attr_reader :modifiers

      # @!method name
      #   Attribute `name`
      #   @see SeregaAttribute::AttributeInstanceMethods#name
      # @!method value
      #   Attribute `value` block
      #   @see SeregaAttribute::AttributeInstanceMethods#value
      # @!method many
      #   Attribute `many` option
      #   @see SeregaAttribute::AttributeInstanceMethods#many
      # @!method serializer
      #   Attribute `serializer` option
      #   @see SeregaAttribute::AttributeInstanceMethods#serializer
      def_delegators :@attribute, :name, :value, :many, :serializer

      #
      # Initializes plan point
      #
      # @param plan [SeregaPlan] Current plan this point belongs to
      # @param attribute [SeregaAttribute] Attribute to construct plan point
      # @param modifiers Serialization parameters
      # @option modifiers [Hash] :only The only attributes to serialize
      # @option modifiers [Hash] :except Attributes to hide
      # @option modifiers [Hash] :with Hidden attributes to serialize additionally
      #
      # @return [SeregaPlanPoint] New plan point
      #
      def initialize(plan, attribute, modifiers = nil)
        @plan = plan
        @attribute = attribute
        @modifiers = modifiers
        set_normalized_vars
      end

      #
      # @return [SeregaObjectSerializer] object serializer for child plan
      #
      def child_object_serializer
        serializer::SeregaObjectSerializer
      end

      private

      # Patched in:
      # - plugin :batch (prepares @batch)
      # - plugin :preloads (prepares @preloads and @preloads_path)
      def set_normalized_vars
        @child_plan = prepare_child_plan
      end

      def prepare_child_plan
        return unless serializer

        fields = modifiers || FROZEN_EMPTY_HASH

        serializer::SeregaPlan.new(self, fields)
      end
    end

    extend SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
