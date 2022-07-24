# frozen_string_literal: true

class Serega
  module Validations
    module Attribute
      class CheckOptKey
        #
        # Checks attribute :key option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        class << self
          def call(opts, block = nil)
            return unless opts.key?(:key)

            check_usage_with_other_params(opts, block)
            Utils::CheckOptIsStringOrSymbol.call(opts, :key)
          end

          private

          def check_usage_with_other_params(opts, block)
            raise Error, "Option :key can not be used together with option :const" if opts.key?(:const)
            raise Error, "Option :key can not be used together with option :value" if opts.key?(:value)
            raise Error, "Option :key can not be used together with block" if block
          end
        end
      end
    end
  end
end
