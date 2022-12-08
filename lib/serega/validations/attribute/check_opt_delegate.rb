# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      #
      # Attribute `:delegate` option validator
      #
      class CheckOptDelegate
        class << self
          #
          # Checks attribute :delegate option
          # It must have :to option and can have :optional allow_nil option
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts, block = nil)
            return unless opts.key?(:delegate)

            check_opt_delegate(opts)
            check_usage_with_other_params(opts, block)
          end

          private

          def check_opt_delegate(opts)
            Utils::CheckOptIsHash.call(opts, :delegate)

            delegate_opts = opts[:delegate]
            check_opt_delegate_to(delegate_opts)
            check_opt_delegate_key(delegate_opts)
            check_opt_delegate_allow_nil(delegate_opts)
          end

          def check_opt_delegate_to(delegate_opts)
            to_exist = delegate_opts.key?(:to)
            raise SeregaError, "Option :delegate must have a :to option" unless to_exist

            Utils::CheckOptIsStringOrSymbol.call(delegate_opts, :to)
          end

          def check_opt_delegate_key(delegate_opts)
            Utils::CheckOptIsStringOrSymbol.call(delegate_opts, :key)
          end

          def check_opt_delegate_allow_nil(delegate_opts)
            Utils::CheckOptIsBool.call(delegate_opts, :allow_nil)
          end

          def check_usage_with_other_params(opts, block)
            raise SeregaError, "Option :delegate can not be used together with option :key" if opts.key?(:key)
            raise SeregaError, "Option :delegate can not be used together with option :const" if opts.key?(:const)
            raise SeregaError, "Option :delegate can not be used together with option :value" if opts.key?(:value)
            raise SeregaError, "Option :delegate can not be used together with block" if block
          end
        end
      end
    end
  end
end
