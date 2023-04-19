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
        require_relative "./lib/loader"
        require_relative "./lib/loaders"
        require_relative "./lib/validations/check_batch_opt_key"
        require_relative "./lib/validations/check_batch_opt_loader"
        require_relative "./lib/validations/check_opt_batch"

        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::SeregaAttributeNormalizer.include(AttributeNormalizerInstanceMethods)
        serializer_class::SeregaPlanPoint.include(MapPointInstanceMethods)
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
          require_relative "./lib/plugins_extensions/activerecord_preloads"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::ActiveRecordPreloads::BatchLoaderInstanceMethods)
        end

        if serializer_class.plugin_used?(:formatters)
          require_relative "./lib/plugins_extensions/formatters"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::Formatters::BatchLoaderInstanceMethods)
          serializer_class::SeregaAttribute.include(PluginsExtensions::Formatters::SeregaAttributeInstanceMethods)
        end

        if serializer_class.plugin_used?(:preloads)
          require_relative "./lib/plugins_extensions/preloads"
          serializer_class::SeregaAttributeNormalizer.include(PluginsExtensions::Preloads::AttributeNormalizerInstanceMethods)
        end

        config = serializer_class.config
        config.attribute_keys << :batch
        config.opts[:batch] = {loaders: {}, default_key: nil, auto_hide: false}
        config.batch.auto_hide = opts[:auto_hide] if opts.key?(:auto_hide)
      end

      #
      # Batch loader config
      #
      class BatchConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        #
        # Defines batch loader
        #
        # @param loader_name [Symbol] Batch loader name, that is used when defining attribute with batch loader.
        # @param block [Proc] Block that can accept 3 parameters - keys, context, plan_point
        #   and returns hash where ids are keys and values are batch loaded objects/
        #
        # @return [void]
        #
        def define(loader_name, &block)
          unless block
            raise SeregaError, "Block must be given to #define method"
          end

          params = block.parameters
          if params.count > 3 || !params.all? { |param| (param[0] == :req) || (param[0] == :opt) }
            raise SeregaError, "Block can have maximum 3 regular parameters"
          end

          loaders[loader_name] = block
        end

        # Shows defined loaders
        # @return [Hash] defined loaders
        def loaders
          opts[:loaders]
        end

        #
        # Finds previously defined batch loader by name
        #
        # @param loader_name [Symbol]
        #
        # @return [Proc] batch loader block
        def fetch_loader(loader_name)
          loaders[loader_name] || (raise SeregaError, "Batch loader with name `#{loader_name.inspect}` was not defined. Define example: config.batch.define(:#{loader_name}) { |keys, ctx, points| ... }")
        end

        # Shows option to auto hide attributes with :batch specified
        # @return [Boolean, nil] option value
        def auto_hide
          opts[:auto_hide]
        end

        # @param value [Boolean] New :auto_hide option value
        # @return [Boolean] New option value
        def auto_hide=(value)
          raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
          opts[:auto_hide] = value
        end

        # Shows default key for :batch option
        # @return [Symbol, nil] default key for :batch option
        def default_key
          opts[:default_key]
        end

        # @param value [Symbol] New :default_key option value
        # @return [Boolean] New option value
        def default_key=(value)
          raise SeregaError, "Must be a Symbol, #{value.inspect} provided" unless value.is_a?(Symbol)
          opts[:default_key] = value
        end
      end

      #
      # Config class additional/patched instance methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        #
        # Returns all batch loaders registered for current serializer
        #
        # @return [Serega::SeregaPlugins::Batch::BatchConfig] configuration for batch loaded attributes
        #
        def batch
          @batch ||= BatchConfig.new(opts.fetch(:batch))
        end
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
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super

          CheckOptBatch.call(opts, block, self.class.serializer_class)
        end
      end

      #
      # Serega::SeregaAttribute additional/patched class methods
      #
      # @see Serega::SeregaAttribute
      #
      module AttributeInstanceMethods
        #
        # @return [nil, Hash] :batch option
        #
        attr_reader :batch

        private

        def set_normalized_vars(normalizer)
          super
          @batch = normalizer.batch
        end
      end

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

      #
      # Serega::SeregaPlanPoint additional/patched class methods
      #
      # @see SeregaAttribute
      #
      module MapPointInstanceMethods
        #
        # Returns attribute :batch option with selected loader
        # @return [Hash] attribute :batch option
        #
        def batch
          return @batch if instance_variable_defined?(:@batch)

          @batch = begin
            batch_option = attribute.batch
            if batch_option
              loader = batch_option[:loader]
              if loader.is_a?(Symbol)
                batch_config = attribute.class.serializer_class.config.batch
                batch_option[:loader] = batch_config.fetch_loader(loader)
              end
            end
            batch_option
          end
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

      #
      # SeregaObjectSerializer additional/patched class methods
      #
      # @see Serega::SeregaObjectSerializer
      #
      module SeregaObjectSerializerInstanceMethods
        private

        def attach_value(object, point, container)
          batch = point.batch
          return super unless batch

          remember_key_for_batch_loading(batch, object, point, container)
        end

        def remember_key_for_batch_loading(batch, object, point, container)
          key = batch[:key].call(object, context)
          opts[:batch_loaders].get(point, self).remember(key, container)
          container[point.name] = nil # Reserve attribute place in resulted hash. We will set correct value later
        end
      end
    end

    register_plugin(Batch.plugin_name, Batch)
  end
end
