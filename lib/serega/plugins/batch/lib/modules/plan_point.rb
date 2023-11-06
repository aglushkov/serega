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
        def batch
          attribute.batch
        end
      end
    end
  end
end
