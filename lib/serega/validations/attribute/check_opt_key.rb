# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      class CheckOptKey
        #
        # Checks attribute :key option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [SeregaError] SeregaError that option has invalid value
        #
        # @return [void]
        #
        class << self
          def call(opts, block = nil)
            return unless opts.key?(:key)

            check_usage_with_other_params(opts, block)
            SeregaUtils::CheckOptIsStringOrSymbol.call(opts, :key)
          end

          private

          def check_usage_with_other_params(opts, block)
            raise SeregaError, "Option :key can not be used together with option :const" if opts.key?(:const)
            raise SeregaError, "Option :key can not be used together with option :value" if opts.key?(:value)
            raise SeregaError, "Option :key can not be used together with block" if block
          end
        end
      end
    end
  end
end
