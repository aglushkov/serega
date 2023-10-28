# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # SeregaAttributeNormalizer additional/patched instance methods
      #
      # @see SeregaAttributeNormalizer::AttributeInstanceMethods
      #
      module AttributeNormalizerInstanceMethods
        #
        # Returns normalized attribute :batch option with prepared :key and
        # :default options. Option :loader will be prepared at serialization
        # time as loaders are usually defined after attributes.
        #
        # @return [Hash] attribute :batch normalized options
        #
        def batch
          return @batch if instance_variable_defined?(:@batch)

          @batch = prepare_batch
        end

        private

        #
        # Patch for original `prepare_hide` method
        #
        # Marks attribute hidden if auto_hide option was set and attribute has batch loader
        #
        def prepare_hide
          res = super
          return res unless res.nil?

          if batch
            self.class.serializer_class.config.batch.auto_hide || nil
          end
        end

        def prepare_batch
          batch = init_opts[:batch]
          return unless batch

          loader = prepare_batch_loader(batch[:loader])

          key = batch[:key] || self.class.serializer_class.config.batch.default_key
          key = prepare_batch_key(key)

          default = batch.fetch(:default) { many ? FROZEN_EMPTY_ARRAY : nil }

          {loader: loader, key: key, default: default}
        end

        def prepare_batch_key(key)
          return proc { |object| object.public_send(key) } if key.is_a?(Symbol)

          params_count = SeregaUtils::ParamsCount.call(key, max_count: 2)
          case params_count
          when 0 then proc { key.call }
          when 1 then proc { |object| key.call(object) }
          else key
          end
        end

        def prepare_batch_loader(loader)
          return loader if loader.is_a?(Symbol)

          params_count = SeregaUtils::ParamsCount.call(loader, max_count: 3)
          case params_count
          when 0 then proc { loader.call }
          when 1 then proc { |object| loader.call(object) }
          when 2 then proc { |object, context| loader.call(object, context) }
          else loader
          end
        end
      end
    end
  end
end
