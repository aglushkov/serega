# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super

          CheckOptBatch.call(opts, block, self.class.serializer_class)
        end
      end
    end
  end
end
