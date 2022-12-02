# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      #
      # Attribute `:many` option validator
      #
      class CheckOptMany
        #
        # Checks attribute :many option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [SeregaError] SeregaError that option has invalid value
        #
        # @return [void]
        #
        def self.call(opts)
          Utils::CheckOptIsBool.call(opts, :many)
        end
      end
    end
  end
end
