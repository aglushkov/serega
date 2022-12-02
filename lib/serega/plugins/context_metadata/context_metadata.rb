# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module ContextMetadata
      DEFAULT_CONTEXT_METADATA_KEY = :meta

      # @return [Symbol] Plugin name
      def self.plugin_name
        :context_metadata
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        serializer_class.plugin(:root, **opts) unless serializer_class.plugin_used?(:root)
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaSerializer.include(SeregaSerializerInstanceMethods)
        serializer_class::CheckSerializeParams.include(CheckSerializeParamsInstanceMethods)
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        meta_key = opts[:context_metadata_key] || DEFAULT_CONTEXT_METADATA_KEY
        config.opts[:context_metadata] = {key: meta_key}
        config.serialize_keys << meta_key
      end

      class ContextMetadataConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def key
          opts.fetch(:key)
        end

        def key=(value)
          opts[:key] = value
        end
      end

      module ConfigInstanceMethods
        def context_metadata
          @context_metadata ||= ContextMetadataConfig.new(opts.fetch(:context_metadata))
        end
      end

      module CheckSerializeParamsInstanceMethods
        def check_opts
          super

          meta_key = self.class.serializer_class.config.context_metadata.key
          SeregaValidations::Utils::CheckOptIsHash.call(opts, meta_key)
        end
      end

      module SeregaSerializerInstanceMethods
        def serialize(object)
          super.tap do |hash|
            add_context_metadata(hash)
          end
        end

        private

        def add_context_metadata(hash)
          context_metadata_key = self.class.serializer_class.config.context_metadata.key
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
