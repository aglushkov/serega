# frozen_string_literal: true

class Serega
  class SeregaConvertItem
    module SeregaConvertItemClassMethods
      def call(object, context, map)
        return unless object

        map.each_with_object({}) do |(attribute, nested_map), result|
          value = attribute.value(object, context)

          result[attribute.name] =
            if nested_map.empty?
              attribute.relation? ? {} : value
            elsif many?(attribute, value)
              value.map { |val| call(val, context, nested_map) }
            else
              call(value, context, nested_map)
            end
        end
      end

      private

      def many?(attribute, object)
        is_many = attribute.many
        is_many.nil? ? object.is_a?(Enumerable) : is_many
      end
    end

    extend Serega::SeregaHelpers::SeregaSerializerClassHelper
    extend SeregaConvertItemClassMethods
  end
end
