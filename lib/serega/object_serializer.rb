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
      attr_reader :context, :plan, :many, :symbol_keys, :opts

      # @param plan [SeregaPlan] Serialization plan
      # @param context [Hash] Serialization context
      # @param many [Boolean] is object is enumerable
      # @param opts [Hash] Any custom options
      #
      # @return [SeregaObjectSerializer] New SeregaObjectSerializer
      def initialize(context:, plan:, many: nil, symbol_keys: false, **opts)
        @context = context
        @plan = plan
        @many = many
        @symbol_keys = symbol_keys
        @opts = opts
      end

      # Serializes object(s)
      #
      # @param object [Object] Serialized object
      #
      # @return [Hash, Array<Hash>, nil] Serialized object(s)
      def serialize(object)
        return if object.nil?

        array?(object, many) ? serialize_array(object) : serialize_object(object)
      end

      private

      def serialize_array(objects)
        objects.map { |object| serialize_object(object) }
      end

      # Patched in:
      # - plugin :presenter (makes presenter_object and serializes it)
      def serialize_object(object)
        plan.points.each_with_object({}) do |point, container|
          serialize_point(object, point, container)
        rescue SeregaError
          raise
        rescue => error
          reraise_with_serialized_attribute_details(error, point)
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
      # - plugin :batch :if extension (removes prepared key)
      def attach_final_value(final_value, point, container)
        container[key(point)] = final_value
      end

      def key(point)
        symbol_keys ? point.symbol_name : point.name
      end

      def final_value(value, point)
        point.child_plan ? relation_value(value, point) : value
      end

      def relation_value(value, point)
        child_serializer(point).serialize(value)
      end

      def child_serializer(point)
        point.child_object_serializer.new(
          context: context,
          symbol_keys: symbol_keys,
          plan: point.child_plan,
          many: point.many,
          **opts
        )
      end

      def array?(object, many)
        many.nil? ? object.is_a?(Enumerable) : many
      end

      def reraise_with_serialized_attribute_details(error, point)
        raise error.exception(<<~MESSAGE.strip)
          #{error.message}
          (when serializing '#{point.name}' attribute in #{self.class.serializer_class})
        MESSAGE
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    include InstanceMethods
  end
end
