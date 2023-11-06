# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Validator for option :loader in attribute :batch option
      #
      class CheckBatchOptLoader
        class << self
          #
          # Checks option :loader of attribute :batch option
          #
          # @param loader [nil, #call] Attribute :batch option :loader
          #
          # @raise [SeregaError] validation error
          #
          # @return [void]
          #
          def call(loader, serializer_class)
            if loader.is_a?(Symbol)
              check_symbol(loader, serializer_class)
            else
              check_callable(loader)
            end
          end

          private

          def check_symbol(loader_name, serializer_class)
            defined_loaders = serializer_class.config.batch.loaders
            return if defined_loaders[loader_name]

            raise SeregaError, <<~ERR.strip
              Please define loader before adding it to attribute.
                Example: `config.batch.define(:#{loader_name}) { |ids| ... }`
            ERR
          end

          def check_callable(loader)
            raise SeregaError, must_be_callable unless loader.respond_to?(:call)

            SeregaValidations::Utils::CheckExtraKeywordArg.call(loader, ":batch option :loader")
            params_count = SeregaUtils::ParamsCount.call(loader, max_count: 3)
            raise SeregaError, params_count_error if params_count > 3
          end

          def params_count_error
            "Invalid :batch option :loader. It can accept maximum 3 parameters (keys, context, plan)"
          end

          def must_be_callable
            "Invalid :batch option :loader. It must be a Symbol, a Proc or respond to :call"
          end
        end
      end
    end
  end
end
