# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      class CheckOptConst
        #
        # Checks attribute :const option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Attribute validation error
        #
        # @return [void]
        #
        class << self
          def call(opts, block = nil)
            return unless opts.key?(:const)

            check_usage_with_other_params(opts, block)
          end

          private

          def check_usage_with_other_params(opts, block)
            raise Error, "Option :const can not be used together with option :key" if opts.key?(:key)
            raise Error, "Option :const can not be used together with option :value" if opts.key?(:value)
            raise Error, "Option :const can not be used together with block" if block
          end
        end
      end
    end
  end
end
