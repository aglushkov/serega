# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Serega::SeregaAttribute additional/patched class methods
      #
      # @see Serega::SeregaAttribute
      #
      module AttributeInstanceMethods
        #
        # @return [nil, Hash] :batch option
        #
        attr_reader :batch

        private

        def set_normalized_vars(normalizer)
          super
          @batch = normalizer.batch
        end
      end
    end
  end
end
