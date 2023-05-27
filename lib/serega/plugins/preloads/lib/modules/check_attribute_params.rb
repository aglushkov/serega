# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super
          CheckOptPreload.call(opts)
          CheckOptPreloadPath.call(opts)
        end
      end
    end
  end
end
