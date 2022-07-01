# frozen_string_literal: true

class Serega
  class ConvertItem
    module ConvertItemClassMethods
      def call(object, context, map)
        return unless object

        map.each_with_object({}) do |(attribute, nested_attributes), hash|
          value = attribute.value(object, context)
          attach_value(value, hash, attribute, nested_attributes, context)
        end
      end

      private

      def attach_value(value, hash, attribute, nested_attributes, context)
        hash[attribute.name] =
          if nested_attributes.empty?
            attribute.relation? ? FROZEN_EMPTY_HASH : value
          elsif many?(attribute, value)
            value.map { |val| call(val, context, nested_attributes) }
          else
            call(value, context, nested_attributes)
          end
      end

      def many?(attribute, object)
        is_many = attribute.many
        is_many.nil? ? object.is_a?(Enumerable) : is_many
      end
    end

    extend Serega::Helpers::SerializerClassHelper
    extend ConvertItemClassMethods
  end
end
