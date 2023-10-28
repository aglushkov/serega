# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module If
      #
      # Validator for attribute :if_value option
      #
      class CheckOptIfValue
        class << self
          #
          # Checks attribute :if_value option that must be [nil, Symbol, Proc, #call]
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts)
            return unless opts.key?(:if_value)

            check_usage_with_other_params(opts)
            check_type(opts[:if_value])
          end

          private

          def check_usage_with_other_params(opts)
            raise SeregaError, "Option :if_value can not be used together with option :serializer" if opts.key?(:serializer)
          end

          def check_type(value)
            return if value.is_a?(Symbol)
            raise SeregaError, must_be_callable unless value.respond_to?(:call)

            SeregaValidations::Utils::CheckExtraKeywordArg.call(value, ":if_value option")
            params_count = SeregaUtils::ParamsCount.call(value, max_count: 2)

            if params_count > 2
              raise SeregaError, "Option :if_value value should have up to 2 parameters (value, context)"
            end
          end

          def must_be_callable
            "Invalid attribute option :if_value. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
