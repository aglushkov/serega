# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Serega::SeregaAttribute additional/patched instance methods
      #
      # @see Serega::SeregaAttribute::AttributeInstanceMethods
      #
      module AttributeInstanceMethods
        # @return [Hash, nil] normalized preloads of current attribute
        attr_reader :preloads

        # @return [Array] normalized preloads_path of current attribute
        attr_reader :preloads_path

        private

        def set_normalized_vars(normalizer)
          super
          @preloads = normalizer.preloads
          @preloads_path = normalizer.preloads_path
        end
      end
    end
  end
end
