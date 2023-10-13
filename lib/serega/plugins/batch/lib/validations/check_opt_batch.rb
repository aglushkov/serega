# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Attribute `:batch` option validator
      #
      class CheckOptBatch
        class << self
          #
          # Checks attribute :batch  option
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(opts, block, serializer_class)
            return unless opts.key?(:batch)

            SeregaValidations::Utils::CheckOptIsHash.call(opts, :batch)

            batch = opts[:batch]
            SeregaValidations::Utils::CheckAllowedKeys.call(batch, %i[key loader default], :batch)

            check_batch_opt_key(batch, serializer_class)
            check_batch_opt_loader(batch)

            check_usage_with_other_params(opts, block)
          end

          private

          def check_batch_opt_key(batch, serializer_class)
            return if !batch.key?(:key) && serializer_class.config.batch.default_key

            key = batch[:key]
            raise SeregaError, "Option :key must present inside :batch option" unless key

            CheckBatchOptKey.call(key)
          end

          def check_batch_opt_loader(batch)
            loader = batch[:loader]
            raise SeregaError, "Option :loader must present inside :batch option" unless loader

            CheckBatchOptLoader.call(loader)
          end

          def check_usage_with_other_params(opts, block)
            raise SeregaError, "Option :batch can not be used together with option :method" if opts.key?(:method)
            raise SeregaError, "Option :batch can not be used together with option :value" if opts.key?(:value)
            raise SeregaError, "Option :batch can not be used together with option :const" if opts.key?(:const)
            raise SeregaError, "Option :batch can not be used together with option :delegate" if opts.key?(:delegate)
            raise SeregaError, "Option :batch can not be used together with block" if block
          end
        end
      end
    end
  end
end
