# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Serega::SeregaPlanPoint additional/patched class methods
      #
      # @see SeregaAttribute
      #
      module PlanPointInstanceMethods
        #
        # Returns attribute :batch option with prepared loader
        # @return [Hash] attribute :batch option
        #
        attr_reader :batch

        private

        def set_normalized_vars
          super
          @batch = prepare_batch
        end

        def prepare_batch
          batch = attribute.batch
          if batch
            loader = batch[:loader]
            if loader.is_a?(Symbol)
              batch_config = attribute.class.serializer_class.config.batch
              batch[:loader] = batch_config.fetch_loader(loader)
            end
          end
          batch
        end
      end
    end
  end
end
