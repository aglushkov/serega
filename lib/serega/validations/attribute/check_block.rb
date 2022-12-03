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
            params = block.parameters
            return if (params.count <= 2) && params.all? { |par| par[0] == :opt }

            raise SeregaError, block_error
          end

          def block_error
            "Block can have maximum two regular parameters (no **keyword or *array args)"
          end
        end
      end
    end
  end
end
