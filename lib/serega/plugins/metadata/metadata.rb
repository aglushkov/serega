# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      # @return [Symbol] Plugin name
      def self.plugin_name
        :metadata
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        if serializer_class.plugin_used?(:root)
          root = serializer_class.config.root
          root.one = opts[:root_one] if opts.key?(:root_one)
          root.many = opts[:root_many] if opts.key?(:root_many)
        else
          serializer_class.plugin(:root, **opts)
        end
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
        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)

        require_relative "./meta_attribute"
        require_relative "./validations/check_block"
        require_relative "./validations/check_opt_hide_nil"
        require_relative "./validations/check_opt_hide_empty"
        require_relative "./validations/check_opts"
        require_relative "./validations/check_path"

        meta_attribute_class = Class.new(MetaAttribute)
        meta_attribute_class.serializer_class = serializer_class
        serializer_class.const_set(:MetaAttribute, meta_attribute_class)
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **_opts)
        serializer_class.config.opts[:metadata] = {attribute_keys: %i[path hide_nil hide_empty]}
      end

      class MetadataConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def attribute_keys
          opts.fetch(:attribute_keys)
        end
      end

      module ConfigInstanceMethods
        def metadata
          @metadata ||= MetadataConfig.new(opts.fetch(:metadata))
        end
      end

      module ClassMethods
        private def inherited(subclass)
          super

          meta_attribute_class = Class.new(self::MetaAttribute)
          meta_attribute_class.serializer_class = subclass
          subclass.const_set(:MetaAttribute, meta_attribute_class)

          # Assign same metadata attributes
          meta_attributes.each_value do |attr|
            subclass.meta_attribute(*attr.path, **attr.opts, &attr.block)
          end
        end

        #
        # List of added metadata attributes
        #
        # @return [Array] Added metadata attributes
        #
        def meta_attributes
          @meta_attributes ||= {}
        end

        #
        # Adds metadata to response
        #
        # @example
        #   class AppSerializer < Serega
        #
        #     meta_attribute(:version) { '1.2.3' }
        #
        #     meta_attribute(:meta, :paging, hide_nil: true, hide_empty: true) do |scope, ctx|
        #       { page: scope.page, per_page: scope.per_page, total_count: scope.total_count }
        #     end
        #   end
        #
        # @param path [String, Symbol, Array<String, Symbol>] Metadata attribute path keys
        # @param opts [Hash] Metadata attribute options
        # @param block [Proc] Block to fetch metadata attribute value
        #
        # @return [MetadataAttribute] Added metadata attribute
        #
        def meta_attribute(*path, **opts, &block)
          attribute = self::MetaAttribute.new(path: path, opts: opts, block: block)
          meta_attributes[attribute.name] = attribute
        end
      end

      module InstanceMethods
        private

        def serialize(object, opts)
          super.tap do |hash|
            context = opts[:context]
            add_metadata(object, context, hash)
          end
        end

        def add_metadata(object, context, hash)
          self.class.meta_attributes.each_value do |meta_attribute|
            metadata = meta_attribute_value(object, context, meta_attribute)
            next unless metadata

            deep_merge_metadata(hash, metadata)
          end
        end

        def meta_attribute_value(object, context, meta_attribute)
          value = meta_attribute.value(object, context)
          return if meta_attribute.hide?(value)

          # Example:
          #  [:foo, :bar].reverse_each.inject(:bazz) { |val, key| { key => val } } # => { foo: { bar: :bazz } }
          meta_attribute.path.reverse_each.inject(value) { |val, key| {key => val} }
        end

        def deep_merge_metadata(hash, metadata)
          hash.merge!(metadata) do |_key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              deep_merge_metadata(this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end

    register_plugin(Metadata.plugin_name, Metadata)
  end
end
