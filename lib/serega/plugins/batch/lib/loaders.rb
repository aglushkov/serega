# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      # Lists batch loaders registered during serialization
      class SeregaBatchLoaders

        # BatchLoaders instance methods
        module InstanceMethods
          #
          # Initializes or fetches already initialized batch loader
          #
          # @param map_point [Serega::SeregaMapPoint] current map point
          # @param object_serializer[Serega::SeregaObjectSerializer] current object serializer
          #
          # @return [Serega::SeregaPlugins::Batch::SeregaBatchLoader] Batch Loader
          #
          def get(map_point, object_serializer)
            batch_loaders[map_point] ||= self.class.serializer_class::SeregaBatchLoader.new(object_serializer, map_point)
          end

          #
          # Loads all registered batches and removes them from registered list
          #
          def load_all
            return unless defined?(@batch_loaders)

            while (_point, batch_loader = batch_loaders.shift)
              batch_loader.load
            end
          end

          private

          def batch_loaders
            @batch_loaders ||= {}.compare_by_identity
          end
        end

        include InstanceMethods
        extend Serega::SeregaHelpers::SerializerClassHelper
      end
    end
  end
end
