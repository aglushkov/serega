# frozen_string_literal: true

class Serega
  module Plugins
    module ContextMetadata
      DEFAULT_CONTEXT_METADATA_KEY = :meta

      def self.plugin_name
        :context_metadata
      end

      def self.before_load_plugin(serializer_class, **opts)
        serializer_class.plugin(:root, **opts) unless serializer_class.plugin_used?(:root)
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        serializer_class::Convert.include(ConvertInstanceMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.config[plugin_name] = {key: opts[:context_metadata_key] || DEFAULT_CONTEXT_METADATA_KEY}
      end

      module InstanceMethods
        def to_h(object, **opts)
          meta_key = self.class.config[:context_metadata][:key]
          meta = opts[meta_key]

          if meta && !meta.is_a?(Hash)
            raise Serega::Error, "Option :#{meta_key} must be a Hash, but #{meta.class} was given"
          end

          super
        end
      end

      module ConvertInstanceMethods
        def to_h
          super.tap do |hash|
            add_context_metadata(hash)
          end
        end

        private

        def add_context_metadata(hash)
          context_metadata_key = self.class.serializer_class.config[:context_metadata][:key]
          return unless context_metadata_key

          metadata = opts[context_metadata_key]
          return unless metadata

          deep_merge_context_metadata(hash, metadata)
        end

        def deep_merge_context_metadata(hash, metadata)
          hash.merge!(metadata) do |_key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              deep_merge_context_metadata(this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end

    register_plugin(ContextMetadata.plugin_name, ContextMetadata)
  end
end
