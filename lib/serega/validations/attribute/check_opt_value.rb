# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      class CheckOptValue
        #
        # Checks attribute :value option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        class << self
          def call(opts, block = nil)
            return unless opts.key?(:value)

            check_usage_with_other_params(opts, block)
            check_proc(opts[:value])
          end

          private

          def check_usage_with_other_params(opts, block)
            raise Error, "Option :value can not be used together with option :key" if opts.key?(:key)
            raise Error, "Option :value can not be used together with option :const" if opts.key?(:const)
            raise Error, "Option :value can not be used together with block" if block
          end

          def check_proc(value)
            raise Error, value_error unless value.is_a?(Proc)

            params = value.parameters

            if value.lambda?
              return if (params.count == 2) && params.all? { |par| par[0] == :req }
            elsif (params.count <= 2) && params.all? { |par| par[0] == :opt }
              return
            end

            raise Error, value_error
          end

          def value_error
            "Option :value must be a Proc that is able to accept two parameters (no **keyword or *array args)"
          end
        end
      end
    end
  end
end
