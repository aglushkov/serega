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
            SeregaValidations::Utils::CheckAllowedKeys.call(batch, %i[id_method loader default], :batch)

            check_batch_opt_id_method(batch, serializer_class)
            check_batch_opt_loader(batch, serializer_class)
            check_usage_with_other_params(opts, block)
          end

          private

          def check_batch_opt_id_method(batch, serializer_class)
            return if !batch.key?(:id_method) && serializer_class.config.batch.id_method

            id_method = batch[:id_method]
            raise SeregaError, "Option :id_method must present inside :batch option" unless id_method

            CheckBatchOptIdMethod.call(id_method)
          end

          def check_batch_opt_loader(batch, serializer_class)
            loader = batch[:loader]
            raise SeregaError, "Option :loader must present inside :batch option" unless loader

            CheckBatchOptLoader.call(loader, serializer_class)
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
