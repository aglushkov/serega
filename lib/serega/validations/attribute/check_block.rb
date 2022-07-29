# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      class CheckBlock
        class << self
          #
          # Checks :value option or a block provided with attribute
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
          # @param opts [Proc] Attribute opts, we will check :value option
          # @param block [Proc] Block that returns serialized attribute value
          #
          # @raise [Error] Error that block has invalid arguments
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

            raise Error, block_error
          end

          def block_error
            "Block can have maximum two regular parameters (no **keyword or *array args)"
          end
        end
      end
    end
  end
end
