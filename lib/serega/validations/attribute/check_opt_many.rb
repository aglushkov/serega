# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      #
      # Attribute `:many` option validator
      #
      class CheckOptMany
        class << self
          #
          # Checks attribute :many option
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] SeregaError that option has invalid value
          #
          # @return [void]
          #
          def call(opts)
            return unless opts.key?(:many)

            check_many_option_makes_sence(opts)
            Utils::CheckOptIsBool.call(opts, :many)
          end

          private

          def check_many_option_makes_sence(opts)
            return if many_option_makes_sence?(opts)

            raise SeregaError, "Option :many can be provided only together with :serializer or :batch option"
          end

          def many_option_makes_sence?(opts)
            opts[:serializer] || opts[:batch]
          end
        end
      end
    end
  end
end
