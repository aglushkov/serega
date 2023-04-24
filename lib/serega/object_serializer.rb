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
      attr_reader :context, :plan, :many, :opts

      # @param plan [SeregaPlan] Serialization plan
      # @param context [Hash] Serialization context
      # @param many [TrueClass|FalseClass] is object is enumerable
      # @param opts [Hash] Any custom options
      #
      # @return [SeregaObjectSerializer] New SeregaObjectSerializer
      def initialize(context:, plan:, many: nil, **opts)
        @context = context
        @plan = plan
        @many = many
        @opts = opts
      end

      # Serializes object(s)
      #
      # @param object [Object] Serialized object
      #
      # @return [Hash, Array<Hash>] Serialized object(s)
      def serialize(object)
        return if object.nil?

        array?(object, many) ? serialize_array(object) : serialize_object(object)
      end

      private

      def serialize_array(object)
        object.map { |obj| serialize_object(obj) }
      end

      # Patched in:
      # - plugin :presenter (makes presenter_object and serializes it)
      def serialize_object(object)
        plan.points.each_with_object({}) do |point, container|
          serialize_point(object, point, container)
        end
      end

      # Patched in:
      # - plugin :if (conditionally skips serializing this point)
      def serialize_point(object, point, container)
        attach_value(object, point, container)
      end

      # Patched in:
      # - plugin :batch (remembers key for batch loading values instead of attaching)
      def attach_value(object, point, container)
        value = point.value(object, context)
        final_value = final_value(value, point)
        attach_final_value(final_value, point, container)
      end

      # Patched in:
      # - plugin :if (conditionally skips attaching)
      def attach_final_value(final_value, point, container)
        container[point.name] = final_value
      end

      def final_value(value, point)
        point.child_plan ? relation_value(value, point) : value
      end

      def relation_value(value, point)
        child_plan = point.child_plan
        child_serializer = point.child_object_serializer
        child_many = point.many
        serializer = child_serializer.new(context: context, plan: child_plan, many: child_many, **opts)
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
