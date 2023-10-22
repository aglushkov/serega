# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module If
      #
      # Validator for attribute :unless option
      #
      class CheckOptUnless
        class << self
          #
          # Checks attribute :unless option that must be [nil, Symbol, Proc, #call]
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts)
            return unless opts.key?(:unless)

            check_type(opts[:unless])
          end

          private

          def check_type(value)
            return if value.is_a?(Symbol)
            raise SeregaError, must_be_callable unless value.respond_to?(:call)

            SeregaValidations::Utils::CheckExtraKeywordArg.call(:unless, value)
            params_count = SeregaUtils::ParamsCount.call(value, max_count: 2)

            if params_count > 2
              raise SeregaError, "Option :unless value should have up to 2 parameters (object, context)"
            end
          end

          def must_be_callable
            "Invalid attribute option :unless. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
