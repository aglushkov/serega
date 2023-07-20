# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module OpenAPI
      #
      # Validator for attribute :many option
      #
      class CheckOptMany
        class << self
          #
          # Checks attribute :many option must be provided with relations
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts)
            serializer = opts[:serializer]
            return unless serializer

            many_option_exists = opts.key?(:many)
            return if many_option_exists

            raise SeregaError,
              "Attribute option :many [Boolean] must be provided" \
              " for attributes with :serializer option" \
              " when :openapi plugin added"
          end
        end
      end
    end
  end
end
