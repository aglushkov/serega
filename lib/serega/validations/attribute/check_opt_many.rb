# frozen_string_literal: true

class Serega
  module Validations
    module Attribute
      class CheckOptMany
        #
        # Checks attribute :many option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
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
