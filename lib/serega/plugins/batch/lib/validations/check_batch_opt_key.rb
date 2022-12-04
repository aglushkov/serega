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

            if key.is_a?(Proc)
              check_block(key)
            else
              check_callable(key)
            end
          end

          private

          def check_block(block)
            return if valid_parameters?(block, accepted_count: 0..2)

            raise SeregaError, block_parameters_error
          end

          def check_callable(callable)
            return if valid_parameters?(callable.method(:call), accepted_count: 2..2)

            raise SeregaError, callable_parameters_error
          end

          def valid_parameters?(data, accepted_count:)
            params = data.parameters
            accepted_count.include?(params.count) && valid_parameters_types?(params)
          end

          def valid_parameters_types?(params)
            params.all? do |param|
              type = param[0]
              (type == :req) || (type == :opt)
            end
          end

          def block_parameters_error
            "Invalid :batch option :key. When it is a Proc it can have maximum two regular parameters (object, context)"
          end

          def callable_parameters_error
            "Invalid :batch option :key. When it is a callable object it must have two regular parameters (object, context)"
          end

          def must_be_callable
            "Invalid :batch option :key. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
