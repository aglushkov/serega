# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Encapsulates point and according object_serializer
      #   so we can put batch loaded values to this serializer response
      #
      class SeregaBatchLoader
        #
        # Batch Loader instance methods
        #
        module InstanceMethods
          # @return [Serega::SeregaPlanPoint]
          attr_reader :point

          # @return [Serega::SeregaObjectSerializer]
          attr_reader :object_serializer

          #
          # Initializes new SeregaBatchLoader
          #
          # @param object_serializer [Serega::SeregaObjectSerializer]
          # @param point [Serega::SeregaPlanPoint]
          #
          # @return [Serega::SeregaPlugins::Batch::SeregaBatchLoader]
          #
          def initialize(object_serializer, point)
            @object_serializer = object_serializer
            @point = point
          end

          #
          # Remembers key and hash container where value for this key must be inserted
          #
          # @param key [Object] key that identifies batch loaded objects
          # @param container [Hash] container where batch loaded objects must be attached
          #
          # @return [void]
          #
          def remember(key, container)
            (keys[key] ||= []) << container
          end

          #
          # Loads this batch and assigns values to remembered containers
          #
          # @return [void]
          #
          def load
            keys_values = keys_values()

            each_key do |key, container|
              value = keys_values.fetch(key) { point.batch[:default] }
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

          # Patched in:
          # - plugin batch (extension :activerecord_preloads - preloads data to found values)
          # - plugin batch (extension :formatters - formats values)
          def keys_values
            ids = keys.keys

            point.batch[:loader].call(ids, object_serializer.context, point).tap do |vals|
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
