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
            params_count = count_and_check_parameters(params, max_count: 2)
            return if (params_count == 1) || (params_count == 2)

            raise SeregaError, block_error
          end

          def count_and_check_parameters(parameters, max_count:)
            count = 0
            parameters.each do |parameter|
              param_type = parameter[0]

              case param_type
              when :req then count += 1
              when :opt then count += 1 if count < max_count
              when :rest then count += max_count - count if max_count > count
              when :keyreq then raise Serega::SeregaError, keyword_error
              end # else :opt, :key, :keyrest, :block - do nothing
            end

            count
          end

          def block_error
            "Block must have one or two parameters (object, context)"
          end

          def keyword_error
            "Block must must not have keyword parameters"
          end
        end
      end
    end
  end
end
