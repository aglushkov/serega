# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      class SeregaBatchLoader
        module InstanceMethods
          attr_reader :object_serializer, :point

          def initialize(object_serializer, point)
            @object_serializer = object_serializer
            @point = point
          end

          def remember(key, container)
            (keys[key] ||= []) << container
          end

          def load
            keys_values = keys_values()

            each_key do |key, container|
              value = keys_values.fetch(key) { point.batch.default_value }
              final_value = object_serializer.__send__(:final_value, value, point)
              object_serializer.__send__(:attach_final_value, final_value, point, container)
            end
          end

          private

          def each_key
            keys.each do |key, containers|
              containers.each do |container|
                yield(key, container)
              end
            end
          end

          def keys_values
            ids = keys.keys

            point.batch.loader.call(ids, object_serializer.context, point.nested_points).tap do |vals|
              next if vals.is_a?(Hash)

              attribute_name = "#{point.class.serializer_class}.#{point.name}"
              raise SeregaError, "Batch loader for `#{attribute_name}` must return Hash, but #{vals.inspect} was returned"
            end
          end

          def keys
            @keys ||= {}
          end
        end

        include InstanceMethods
        extend Serega::SeregaHelpers::SerializerClassHelper
      end
    end
  end
end
