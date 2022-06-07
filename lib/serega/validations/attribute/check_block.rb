# frozen_string_literal: true

class Serega
  class Attribute
    class CheckBlock
      module ClassMethods
        ALLOWED_PARAM_TYPES = %i[opt req]
        private_constant :ALLOWED_PARAM_TYPES

        #
        # Checks block provided with attribute
        # Block must have up to two arguments - object and context.
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
        # @raise [Error] Error that block has invalid arguments
        #
        # @return [void]
        #
        def call(block)
          return unless block

          params = block.parameters
          return if (params.count <= 2) && params.all? { |par| ALLOWED_PARAM_TYPES.include?(par[0]) }

          raise Error, "Block can have maximum 2 regular parameters (no **keyword or *array args)"
        end
      end

      extend ClassMethods
    end
  end
end
