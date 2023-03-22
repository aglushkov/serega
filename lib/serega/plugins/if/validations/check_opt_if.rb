# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module If
      #
      # Validator for attribute :if option
      #
      class CheckOptIf
        class << self
          #
          # Checks attribute :if option that must be [nil, Symbol, Proc, #call]
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts)
            return unless opts.key?(:if)

            check_type(opts[:if])
          end

          private

          def check_type(value)
            return if value.is_a?(Symbol)

            raise SeregaError, must_be_callable unless value.respond_to?(:call)

            if value.is_a?(Proc)
              check_block(value)
            else
              check_callable(value)
            end
          end

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
            "Invalid attribute option :if. When it is a Proc it can have maximum two regular parameters (object, context)"
          end

          def callable_parameters_error
            "Invalid attribute option :if. When it is a callable object it must have two regular parameters (object, context)"
          end

          def must_be_callable
            "Invalid attribute option :if. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
