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
        serializer_class::Convert.include(ConvertInstanceMethods)
        serializer_class::CheckSerializeParams.extend(CheckSerializeParamsClassMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        meta_key = opts[:context_metadata_key] || DEFAULT_CONTEXT_METADATA_KEY
        config[plugin_name] = {key: meta_key}
        config[:serialize_keys] << meta_key
      end

      module CheckSerializeParamsClassMethods
        def check_opts(opts)
          super

          meta_key = serializer_class.config[:context_metadata][:key]
          Validations::Utils::CheckOptIsHash.call(opts, meta_key)
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
