# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Validator for option :id_method in attribute :batch option
      #
      class CheckBatchOptIdMethod
        class << self
          #
          # Checks option :id_method of attribute :batch option
          #
          # @param id [nil, #call] Attribute :batch option :id_method
          #
          # @raise [SeregaError] validation error
          #
          # @return [void]
          #
          def call(id)
            return if id.is_a?(Symbol)

            raise SeregaError, must_be_callable unless id.respond_to?(:call)

            signature = SeregaUtils::MethodSignature.call(id, pos_limit: 2, keyword_args: [])
            raise SeregaError, signature_error unless %w[0 1 2].include?(signature)
          end

          private

          def signature_error
            "Invalid :batch option :id_method. It can accept maximum 2 parameters (object, context)"
          end

          def must_be_callable
            "Invalid :batch option :id_method. It must be a Symbol, a Proc or respond to #call"
          end
        end
      end
    end
  end
end
