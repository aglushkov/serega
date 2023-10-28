# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Attribute parameters validators
    #
    module Attribute
      #
      # Attribute `block` parameter validator
      #
      class CheckBlock
        class << self
          #
          # Checks block parameter provided with attribute.
          # Must have up to two arguments - object and context.
          # It should not have any *rest or **key arguments
          #
          # @example without arguments
          #   attribute(:email) { CONSTANT_EMAIL }
          #
          # @example with one argument
          #   attribute(:email) { |obj| obj.confirmed_email }
          #
          # @example with two arguments
          #   attribute(:email) { |obj, context| context['is_current'] ? obj.email : nil }
          #
          # @param block [Proc] Block that returns serialized attribute value
          #
          # @raise [SeregaError] SeregaError that block has invalid arguments
          #
          # @return [void]
          #
          def call(block)
            return unless block

            check_block(block)
          end

          private

          def check_block(block)
            SeregaValidations::Utils::CheckExtraKeywordArg.call(block, "block")
            params_count = SeregaUtils::ParamsCount.call(block, max_count: 2)

            raise SeregaError, block_error if params_count > 2
          end

          def block_error
            "Block can have maximum two parameters (object, context)"
          end
        end
      end
    end
  end
end
