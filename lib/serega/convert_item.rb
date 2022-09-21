# frozen_string_literal: true

class Serega
  class SeregaConvertItem
    module SeregaConvertItemClassMethods
      def call(object, context, map)
        return unless object

        map.each_with_object({}) do |(attribute, nested_attributes), hash|
          value = attribute.value(object, context)
          attach_value(value, hash, attribute, nested_attributes, context)
        end
      end

      private

      def attach_value(value, hash, attribute, nested_attributes, context)
        attribute_name = attribute.name
        with_context_path(context, attribute_name) do
          hash[attribute_name] =
            if nested_attributes.empty?
              attribute.relation? ? FROZEN_EMPTY_HASH : value
            elsif many?(attribute, value)
              value.map.with_index do |val, index|
                with_context_path(context, index) { call(val, context, nested_attributes) }
              end
            else
              call(value, context, nested_attributes)
            end
        end
      end

      def many?(attribute, object)
        is_many = attribute.many
        is_many.nil? ? object.is_a?(Enumerable) : is_many
      end

      def with_context_path(context, path)
        paths = context[:_path] ||= []
        paths << path
        result = yield
        paths.pop
        result
      end
    end

    extend Serega::SeregaHelpers::SerializerClassHelper
    extend SeregaConvertItemClassMethods
  end
end
