# frozen_string_literal: true

class Serega
  module Plugins
    module Metadata
      def self.plugin_name
        :metadata
      end

      def self.before_load_plugin(serializer_class, **opts)
        serializer_class.plugin(:root, **opts) unless serializer_class.plugin_used?(:root)
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class::Convert.include(ConvertInstanceMethods)

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

      def self.after_load_plugin(serializer_class, **_opts)
        serializer_class.config[plugin_name] = {allowed_opts: %i[hide_nil hide_empty]}
      end

      module ClassMethods
        private def inherited(subclass)
          super

          meta_attribute_class = Class.new(self::MetaAttribute)
          meta_attribute_class.serializer_class = subclass
          subclass.const_set(:MetaAttribute, meta_attribute_class)

          # Assign same attributes
          meta_attributes.each do |attr|
            subclass.meta_attribute(*attr.path, **attr.opts, &attr.block)
          end
        end

        #
        # List of added metadata attributes
        #
        # @return [Array] Added metadata attributes
        #
        def meta_attributes
          @meta_attributes ||= []
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
        # @param *path [Array<String, Symbol>] Metadata attribute path keys
        # @param **opts [Hash] Metadata attribute options
        # @param &block [Proc] Metadata attribute value
        #
        # @return [MetadataAttribute] Added metadata attribute
        #
        def meta_attribute(*path, **opts, &block)
          meta_attribute = self::MetaAttribute.new(path: path, opts: opts, block: block)
          meta_attributes << meta_attribute
        end
      end

      module ConvertInstanceMethods
        def to_h
          super.tap do |hash|
            add_metadata(hash)
          end
        end

        private

        def add_metadata(hash)
          self.class.serializer_class.meta_attributes.each do |meta_attribute|
            metadata = meta_attribute_value(meta_attribute)
            next unless metadata

            deep_merge_metadata(hash, metadata)
          end
        end

        def meta_attribute_value(meta_attribute)
          value = meta_attribute.value(object, opts[:context])
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
