# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module If
      #
      # Validator for attribute :if_value option
      #
      class CheckOptIfValue
        class << self
          #
          # Checks attribute :if_value option that must be [nil, Symbol, Proc, #call]
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts)
            return unless opts.key?(:if_value)

            check_usage_with_other_params(opts)
            check_type(opts[:if_value])
          end

          private

          def check_usage_with_other_params(opts)
            raise SeregaError, "Option :if_value can not be used together with option :serializer" if opts.key?(:serializer)
          end

          def check_type(value)
            return if value.is_a?(Symbol)
            raise SeregaError, must_be_callable unless value.respond_to?(:call)

            signature = SeregaUtils::MethodSignature.call(value, pos_limit: 2, keyword_args: [:ctx])
            raise SeregaError, signature_error unless valid_signature?(signature)
          end

          def must_be_callable
            "Invalid attribute option :if_value. It must be a Symbol, a Proc or respond to :call"
          end

          def valid_signature?(signature)
            case signature
            when "0"      # no parameters
              true
            when "1"      # (value)
              true
            when "2"      # (value, context)
              true
            when "1_ctx"  # (value, :ctx)
              true
            else
              false
            end
          end

          def signature_error
            <<~ERROR.strip
              Invalid attribute option :if_value parameters, valid parameters signatures:
              - ()               # no parameters
              - (value)          # one positional parameter
              - (value, context) # two positional parameters
              - (value, :ctx)    # one positional parameter and :ctx keyword
            ERROR
          end
        end
      end
    end
  end
end
