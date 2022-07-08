# frozen_string_literal: true

class Serega
  class Attribute
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
        def call(opts, block)
          check_both_provided(opts, block)

          if block
            check_block(block)
          elsif opts.key?(:value)
            check_value(opts[:value])
          end
        end

        private

        def check_both_provided(opts, block)
          if opts.key?(:value) && block
            raise Error, both_error
          end
        end

        def check_block(block)
          params = block.parameters
          return if (params.count <= 2) && params.all? { |par| par[0] == :opt }

          raise Error, block_error
        end

        def check_value(value)
          raise Error, value_error unless value.is_a?(Proc)

          params = value.parameters

          if value.lambda?
            return if (params.count == 2) && params.all? { |par| par[0] == :req }
          elsif (params.count <= 2) && params.all? { |par| par[0] == :opt }
            return
          end

          raise Error, value_error
        end

        def block_error
          "Block can have maximum two regular parameters (no **keyword or *array args)"
        end

        def value_error
          "Option :value must be a Proc that is able to accept two parameters (no **keyword or *array args)"
        end

        def both_error
          "Block and a :value option can not be provided together"
        end
      end
    end
  end
end
