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
      # @return [SeregaPlan, nil] Attribute serialization plan
      attr_reader :child_fields

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
      # @param plan [SeregaPlan] Plan where this point belongs to.
      # @param attribute [SeregaAttribute] Attribute to construct plan point
      # @param child_fields [Hash, nil] Child fields (:only, :with, :except)
      #
      # @return [SeregaPlanPoint] New plan point
      #
      def initialize(attribute, plan = nil, child_fields = nil)
        @plan = plan
        @attribute = attribute
        @child_fields = child_fields
        set_normalized_vars
        freeze
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

        fields = child_fields || FROZEN_EMPTY_HASH

        serializer::SeregaPlan.new(
          parent_plan_point: self,
          only: fields[:only] || FROZEN_EMPTY_HASH,
          with: fields[:with] || FROZEN_EMPTY_HASH,
          except: fields[:except] || FROZEN_EMPTY_HASH
        )
      end
    end

    extend SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
