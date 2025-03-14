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
          # Must have up to two arguments - object and context. Context can be
          # also provided as keyword argument :ctx.
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
          # @example with one argument and keyword context
          #   attribute(:email) { |obj, ctx:| obj.email if ctx[:show] }
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
            signature = SeregaUtils::MethodSignature.call(block, pos_limit: 2, keyword_args: [:ctx])

            raise SeregaError, signature_error unless valid_signature?(signature)
          end

          def valid_signature?(signature)
            case signature
            when "0"      # no parameters
              true
            when "1"      # (object)
              true
            when "2"      # (object, context)
              true
            when "1_ctx"  # (object, :ctx)
              true
            else
              false
            end
          end

          def signature_error
            <<~ERROR.strip
              Invalid attribute block parameters, valid parameters signatures:
              - ()                # no parameters
              - (object)          # one positional parameter
              - (object, context) # two positional parameters
              - (object, :ctx)    # one positional parameter and :ctx keyword
            ERROR
          end
        end
      end
    end
  end
end
