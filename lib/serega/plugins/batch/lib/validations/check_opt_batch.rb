# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      class CheckOptBatch
        class << self
          def call(opts, block)
            return unless opts.key?(:batch)

            SeregaValidations::Utils::CheckOptIsHash.call(opts, :batch)

            batch = opts[:batch]
            SeregaValidations::Utils::CheckAllowedKeys.call(batch, %i[key loader default])

            check_batch_opt_key(batch[:key])
            check_batch_opt_loader(batch[:loader])

            check_usage_with_other_params(opts, block)
          end

          private

          def check_batch_opt_key(key)
            raise SeregaError, "Option :key must present inside :batch option" unless key

            CheckBatchOptKey.call(key)
          end

          def check_batch_opt_loader(loader)
            raise SeregaError, "Option :loader must present inside :batch option" unless loader

            CheckBatchOptLoader.call(loader)
          end

          def check_usage_with_other_params(opts, block)
            raise SeregaError, "Option :batch can not be used together with option :key" if opts.key?(:key)
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
