# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      class SeregaBatchLoaders
        module InstanceMethods
          def get(point, object_serializer)
            batch_loaders[point] ||= self.class.serializer_class::SeregaBatchLoader.new(object_serializer, point)
          end

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
