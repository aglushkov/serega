# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      class CheckBatchOptLoader
        class << self
          def call(loader)
            return if loader.is_a?(Symbol)

            raise SeregaError, must_be_callable unless loader.respond_to?(:call)

            if loader.is_a?(Proc)
              check_block(loader)
            else
              check_callable(loader)
            end
          end

          private

          def check_block(block)
            return if valid_parameters?(block, accepted_count: 0..3)

            raise SeregaError, block_parameters_error
          end

          def check_callable(callable)
            return if valid_parameters?(callable.method(:call), accepted_count: 3..3)

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
            "Invalid :batch option :loader. When it is a Proc it can have maximum three regular parameters (keys, context, points)"
          end

          def callable_parameters_error
            "Invalid :batch option :loader. When it is a callable object it must have three regular parameters (keys, context, points)"
          end

          def must_be_callable
            "Invalid :batch option :loader. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
