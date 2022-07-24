# frozen_string_literal: true

class Serega
  module Validations
    module Attribute
      class CheckOptHide
        #
        # Checks attribute :hide option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        def self.call(opts)
          Utils::CheckOptIsBool.call(opts, :hide)
        end
      end
    end
  end
end
