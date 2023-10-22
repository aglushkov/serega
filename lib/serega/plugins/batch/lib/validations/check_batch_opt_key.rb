# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Validator for option :key in attribute :batch option
      #
      class CheckBatchOptKey
        class << self
          #
          # Checks option :key of attribute :batch option
          #
          # @param key [nil, #call] Attribute :batch option :key
          #
          # @raise [SeregaError] validation error
          #
          # @return [void]
          #
          def call(key)
            return if key.is_a?(Symbol)

            raise SeregaError, must_be_callable unless key.respond_to?(:call)

            SeregaValidations::Utils::CheckExtraKeywordArg.call(:key, key)
            params_count = SeregaUtils::ParamsCount.call(key, max_count: 2)
            raise SeregaError, params_count_error if (params_count != 1) && (params_count != 2)
          end

          private

          def params_count_error
            "Invalid :batch option :key. When it is a callable object it must have 1 or 2 parameters (object, context)"
          end

          def must_be_callable
            "Invalid :batch option :key. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
