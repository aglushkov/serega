# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin that can be used to load attributes values in batches.
    #   Each batch loader accepts list of selected keys, context and current attribute point.
    #   Each batch loader must return Hash with values grouped by provided keys.
    #   There are specific `:default` option that can be used to add default value for missing key.
    #
    # @example
    #   class PostSerializer < Serega
    #     plugin :batch
    #
    #     # Define batch loader via callable class, it must accept three args (keys, context, map_point)
    #     attribute :comments_count, batch: { key: :id, loader: PostCommentsCountBatchLoader, default: 0}
    #
    #     # Define batch loader via Symbol, later we should define this loader via config.batch_loaders.define(:posts_comments_counter) { ... }
    #     attribute :comments_count, batch: { key: :id, loader: :posts_comments_counter, default: 0}
    #
    #     # Define batch loader with serializer
    #     attribute :comments, serializer: CommentSerializer, batch: { key: :id, loader: :posts_comments, default: []}
    #
    #     # Resulted block must return hash like { key => value(s) }
    #     config.batch_loaders.define(:posts_comments_counter) do |keys|
    #       Comment.group(:post_id).where(post_id: keys).count
    #     end
    #
    #     # We can return objects that will be automatically serialized if attribute defined with :serializer
    #     # Parameter `context` can be used when loading batch
    #     # Parameter `map_point` can be used to find nested attributes that will be serialized (`map_point.preloads`)
    #     config.batch_loaders.define(:posts_comments) do |keys, context, map_point|
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
        serializer_class::SeregaMapPoint.include(MapPointInstanceMethods)
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
        config = serializer_class.config
        config.attribute_keys << :batch
        config.opts[:batch] = {loaders: {}}
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
        end

        if serializer_class.plugin_used?(:preloads)
          require_relative "./lib/plugins_extensions/preloads"
          serializer_class::SeregaAttribute.include(PluginsExtensions::Preloads::AttributeInstanceMethods)
        end
      end

      #
      # Batch loader config
      #
      class BatchLoadersConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        #
        # Defines batch loader
        #
        # @param loader_name [Symbol] Batch loader name, that is used when defining attribute with batch loader.
        # @param block [Proc] Block that can accept 3 parameters - keys, context, map_point
        #   and returns hash where ids are keys and values are batch loaded objects/
        #
        # @return [void]
        #
        def define(loader_name, &block)
          unless block
            raise SeregaError, "Block must be given to batch_loaders.define method"
          end

          params = block.parameters
          if params.count > 3 || !params.map!(&:first).all? { |type| (type == :req) || (type == :opt) }
            raise SeregaError, "Block can have maximum 3 regular parameters"
          end

          opts[loader_name] = block
        end

        #
        # Finds previously defined batch loader by name
        #
        # @param loader_name [Symbol]
        #
        # @return [Proc] batch loader block
        def fetch(loader_name)
          opts[loader_name] || (raise SeregaError, "Batch loader with name `#{loader_name.inspect}` was not defined. Define example: config.batch_loaders.define(:#{loader_name}) { |keys, ctx, points| ... }")
        end
      end

      #
      # Stores batch config for specific attribute
      #
      class BatchModel
        attr_reader :opts, :loaders, :many

        #
        # Initializes batch model
        #
        # @param opts [Hash] Attribute :batch option
        # @param loaders [Array] Array of all loaders defined in serialize class
        # @param many [Boolean] Option :many, defined on attribute
        #
        # @return [void]
        def initialize(opts, loaders, many)
          @opts = opts
          @loaders = loaders
          @many = many
        end

        # Returns proc that will be used to batch load registered keys values
        # @return [#call] batch loader
        def loader
          @batch_loader ||= begin
            loader = opts[:loader]
            loader = loaders.fetch(loader) if loader.is_a?(Symbol)
            loader
          end
        end

        # Returns proc that will be used to find batch_key for current attribute.
        # @return [Object] key (uid) of batch loaded object
        def key
          @batch_key ||= begin
            key = opts[:key]
            key.is_a?(Symbol) ? proc { |object| object.public_send(key) } : key
          end
        end

        # Returns default value to use if batch loader does not return value for some key
        # @return [Object] default value for missing key
        def default_value
          if opts.key?(:default)
            opts[:default]
          elsif many
            FROZEN_EMPTY_ARRAY
          end
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
        # @return [Serega::SeregaPlugins::Batch::BatchLoadersConfig] configuration for batch loaders
        #
        def batch_loaders
          @batch_loaders ||= BatchLoadersConfig.new(opts.fetch(:batch).fetch(:loaders))
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

          CheckOptBatch.call(opts, block)
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
        def batch
          opts[:batch]
        end
      end

      #
      # Serega::SeregaMapPoint additional/patched class methods
      #
      # @see SeregaAttribute
      #
      module MapPointInstanceMethods
        #
        # Returns BatchModel, an object that encapsulates all batch_loader methods for current point
        #
        # @return [BatchModel] batch model that encapsulates everything needed to load current batch
        #
        def batch
          return @batch if instance_variable_defined?(:@batch)

          @batch = begin
            opts = attribute.batch
            BatchModel.new(opts, self.class.serializer_class.config.batch_loaders, many) if opts
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

          if batch
            key = batch.key.call(object, context)
            opts[:batch_loaders].get(point, self).remember(key, container)
            container[point.name] = nil # Reserve attribute place in resulted hash. We will set correct value later
          else
            super
          end
        end
      end
    end

    register_plugin(Batch.plugin_name, Batch)
  end
end
