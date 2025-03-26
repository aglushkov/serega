# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      #
      # Attribute `:method` option validator
      #
      class CheckOptMethod
        class << self
          #
          # Checks attribute :method option
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] SeregaError that option has invalid value
          #
          # @return [void]
          #
          def call(opts, block = nil)
            return unless opts.key?(:method)

            check_usage_with_other_params(opts, block)
            Utils::CheckOptIsStringOrSymbol.call(opts, :method)
          end

          private

          def check_usage_with_other_params(opts, block)
            raise SeregaError, "Option :method can not be used together with option :const" if opts.key?(:const)
            raise SeregaError, "Option :method can not be used together with option :value" if opts.key?(:value)
            raise SeregaError, "Option :method can not be used together with option :lazy" if opts.key?(:lazy)
            raise SeregaError, "Option :method can not be used together with block" if block
          end
        end
      end
    end
  end
end
