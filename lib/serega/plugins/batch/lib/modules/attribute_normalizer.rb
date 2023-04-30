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

          # take loader
          loader = batch[:loader]

          # take key
          key = batch[:key] || self.class.serializer_class.config.batch.default_key
          proc_key =
            if key.is_a?(Symbol)
              proc do |object|
                handle_no_method_error { object.public_send(key) }
              end
            else
              key
            end

          # take default value
          default = batch.fetch(:default) { many ? FROZEN_EMPTY_ARRAY : nil }

          {loader: loader, key: proc_key, default: default}
        end

        def handle_no_method_error
          yield
        rescue NoMethodError => error
          raise error, "NoMethodError when serializing '#{name}' attribute in #{self.class.serializer_class}\n\n#{error.message}", error.backtrace
        end
      end
    end
  end
end
