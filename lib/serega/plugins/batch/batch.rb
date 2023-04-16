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
    #     # Define batch loader via callable class, it must accept three args (keys, context, plan_point)
    #     attribute :comments_count, batch: { key: :id, loader: PostCommentsCountBatchLoader, default: 0}
    #
    #     # Define batch loader via Symbol, later we should define this loader via config.batch.define(:posts_comments_counter) { ... }
    #     attribute :comments_count, batch: { key: :id, loader: :posts_comments_counter, default: 0}
    #
    #     # Define batch loader with serializer
    #     attribute :comments, serializer: CommentSerializer, batch: { key: :id, loader: :posts_comments, default: []}
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
        require_relative "./lib/batch_option_model"
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
        config.opts[:batch] = {loaders: {}}
        config.batch.auto_hide = opts[:auto_hide] || false
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
          opts.fetch(:auto_hide)
        end

        # @param value [Boolean] New :auto_hide option value
        # @return [Boolean] New option value
        def auto_hide=(value)
          raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
          opts[:auto_hide] = value
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
          init_opts[:batch]
        end
      end

      #
      # Serega::SeregaPlanPoint additional/patched class methods
      #
      # @see SeregaAttribute
      #
      module MapPointInstanceMethods
        #
        # Returns BatchOptionModel, an object that combines options and methods needed to load batch
        #
        # @return [BatchOptionModel] Class that combines options and methods needed to load batch.
        #
        def batch
          return @batch if instance_variable_defined?(:@batch)

          @batch = begin
            opts = attribute.batch
            BatchOptionModel.new(attribute) if opts
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
          key = batch.key.call(object, context)
          opts[:batch_loaders].get(point, self).remember(key, container)
          container[point.name] = nil # Reserve attribute place in resulted hash. We will set correct value later
        end
      end
    end

    register_plugin(Batch.plugin_name, Batch)
  end
end
