# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class MetaAttribute
        class CheckBlock
          ALLOWED_PARAM_TYPES = %i[opt req]
          private_constant :ALLOWED_PARAM_TYPES

          class << self
            #
            # Checks block provided with attribute
            # Block must have up to two arguments - object and context.
            # It should not have any *rest or **key arguments
            #
            # @example without arguments
            #   metadata(:version) { CONSTANT_VERSION }
            #
            # @example with one argument
            #   metadata(:paging) { |scope| { { page: scope.page, per_page: scope.per_page, total_count: scope.total_count } }
            #
            # @example with two arguments
            #   metadata(:paging) { |scope, context| { { ... } if context[:with_paging] }
            #
            # @param block [Proc] Block that returns serialized meta attribute value
            #
            # @raise [Error] Error that block has invalid arguments
            #
            # @return [void]
            #
            def call(block)
              raise Error, "Block must be provided when defining meta attribute" unless block

              params = block.parameters
              return if (params.count <= 2) && params.all? { |par| ALLOWED_PARAM_TYPES.include?(par[0]) }

              raise Error, "Block can have maximum 2 regular parameters (no **keyword or *array args)"
            end
          end
        end
      end
    end
  end
end
