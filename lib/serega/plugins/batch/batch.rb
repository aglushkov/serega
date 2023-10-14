# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin `:batch`
    #
    # Adds ability to load nested attributes values in batches.
    #
    # It can be used to find value for attributes in optimal way:
    # - load associations for multiple objects
    # - load counters for multiple objects
    # - make any heavy calculations for multiple objects only once
    #
    # After including plugin, attributes gain new `:batch` option.
    #
    # `:batch` option must be a hash with this keys:
    # - `key` (required) [Symbol, Proc, callable] - Defines current object identifier.
    #   Later `loader` will accept array of `keys` to find `values`.
    # - `loader` (required) [Symbol, Proc, callable] - Defines how to fetch values for
    #   batch of keys. Receives 3 parameters: keys, context, plan_point.
    # - `default` (optional) - Default value for attribute.
    #   By default it is `nil` or `[]` when attribute has option `many: true`
    #
    # If `:loader` was defined using name (as Symbol) then batch loader must be
    # defined in serializer config: `config.batch.define(:loader_name) { ... }` method.
    #
    # *Result of this `:loader` callable must be a **Hash** where*:
    # - keys - provided keys
    # - values - values for according keys
    #
    # `Batch` plugin can be defined with two specific attributes:
    # - `auto_hide: true` - Marks attributes with defined :batch as hidden, so it
    #   will not be serialized by default
    # - `default_key: :id` - Set default object key (in this case :id) that will be used for all attributes with :batch option specified.
    #
    # This options (`auto_hide`, `default_key`) also can be set as config options in
    # any nested serializer.
    #
    # @example
    #   class PostSerializer < Serega
    #     plugin :batch, auto_hide: true, default_key: :id
    #
    #     # Define batch loader via callable class, it must accept three args (keys, context, plan_point)
    #     attribute :comments_count, batch: { loader: PostCommentsCountBatchLoader, default: 0}
    #
    #     # Define batch loader via Symbol, later we should define this loader via config.batch.define(:posts_comments_counter) { ... }
    #     attribute :comments_count, batch: { loader: :posts_comments_counter, default: 0}
    #
    #     # Define batch loader with serializer
    #     attribute :comments, serializer: CommentSerializer, batch: { loader: :posts_comments, default: []}
    #
    #     # Resulted block must return hash like { key => value(s) }
    #     config.batch.define(:posts_comments_counter) do |keys|
    #       Comment.group(:post_id).where(post_id: keys).count
    #     end
    #
    #     # We can return objects that will be automatically serialized if attribute defined with :serializer
    #     # Parameter `context` can be used when loading batch
    #     # Parameter `plan_point` can be used to find nested attributes that will be serialized (`plan_point.preloads`)
    #     config.batch.define(:posts_comments) do |keys, context, plan_point|
    #       Comment.where(post_id: keys).where(is_spam: false).group_by(&:post_id)
    #     end
    #   end
    #
    module Batch
      # Returns plugin name
      # @return [Symbol] Plugin name
      def self.plugin_name
        :batch
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
        require_relative "lib/batch_config"
        require_relative "lib/loader"
        require_relative "lib/loaders"
        require_relative "lib/modules/attribute"
        require_relative "lib/modules/attribute_normalizer"
        require_relative "lib/modules/check_attribute_params"
        require_relative "lib/modules/config"
        require_relative "lib/modules/object_serializer"
        require_relative "lib/modules/plan_point"
        require_relative "lib/validations/check_batch_opt_key"
        require_relative "lib/validations/check_batch_opt_loader"
        require_relative "lib/validations/check_opt_batch"

        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::SeregaAttributeNormalizer.include(AttributeNormalizerInstanceMethods)
        serializer_class::SeregaPlanPoint.include(PlanPointInstanceMethods)
        serializer_class::SeregaObjectSerializer.include(SeregaObjectSerializerInstanceMethods)
      end

      #
      # Runs callbacks after plugin was attached
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)

        batch_loaders_class = Class.new(SeregaBatchLoaders)
        batch_loaders_class.serializer_class = serializer_class
        serializer_class.const_set(:SeregaBatchLoaders, batch_loaders_class)

        batch_loader_class = Class.new(SeregaBatchLoader)
        batch_loader_class.serializer_class = serializer_class
        serializer_class.const_set(:SeregaBatchLoader, batch_loader_class)

        if serializer_class.plugin_used?(:activerecord_preloads)
          require_relative "lib/plugins_extensions/activerecord_preloads"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::ActiveRecordPreloads::BatchLoaderInstanceMethods)
        end

        if serializer_class.plugin_used?(:formatters)
          require_relative "lib/plugins_extensions/formatters"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::Formatters::BatchLoaderInstanceMethods)
          serializer_class::SeregaAttribute.include(PluginsExtensions::Formatters::SeregaAttributeInstanceMethods)
        end

        if serializer_class.plugin_used?(:preloads)
          require_relative "lib/plugins_extensions/preloads"
          serializer_class::SeregaAttributeNormalizer.include(PluginsExtensions::Preloads::AttributeNormalizerInstanceMethods)
        end

        config = serializer_class.config
        config.attribute_keys << :batch
        config.opts[:batch] = {loaders: {}, default_key: nil, auto_hide: false}
        config.batch.auto_hide = opts[:auto_hide] if opts.key?(:auto_hide)
        config.batch.default_key = opts[:default_key] if opts.key?(:default_key)
      end

      #
      # Serega class additional/patched class methods
      #
      # @see Serega::SeregaConfig
      #
      module ClassMethods
        private

        def inherited(subclass)
          super

          batch_loaders_class = Class.new(self::SeregaBatchLoaders)
          batch_loaders_class.serializer_class = subclass
          subclass.const_set(:SeregaBatchLoaders, batch_loaders_class)

          batch_loader_class = Class.new(self::SeregaBatchLoader)
          batch_loader_class.serializer_class = subclass
          subclass.const_set(:SeregaBatchLoader, batch_loader_class)
        end
      end

      #
      # Serega additional/patched instance methods
      #
      # @see Serega::InstanceMethods
      #
      module InstanceMethods
        private

        #
        # Loads batch loaded attributes after serialization
        #
        def serialize(object, opts)
          batch_loaders = opts[:batch_loaders] = self.class::SeregaBatchLoaders.new
          result = super
          batch_loaders.load_all
          result
        end
      end
    end

    register_plugin(Batch.plugin_name, Batch)
  end
end
