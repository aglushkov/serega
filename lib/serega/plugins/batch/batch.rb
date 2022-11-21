# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      def self.plugin_name
        :batch
      end

      def self.load_plugin(serializer_class, **_opts)
        require_relative "./lib/loader"
        require_relative "./lib/loaders"
        require_relative "./lib/validations/check_batch_opt_key"
        require_relative "./lib/validations/check_batch_opt_loader"
        require_relative "./lib/validations/check_opt_batch"

        serializer_class.extend(ClassMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::SeregaMapPoint.include(MapPointInstanceMethods)
        serializer_class::SeregaSerializer.include(SeregaSerializerInstanceMethods)
        serializer_class::SeregaObjectSerializer.include(SeregaObjectSerializerInstanceMethods)
      end

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
          require_relative "./lib/plugins_extensions"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::ActiveRecordPreloads::BatchLoaderInstanceMethods)
        end

        if serializer_class.plugin_used?(:formatters)
          require_relative "./lib/plugins_extensions"
          serializer_class::SeregaBatchLoader.include(PluginsExtensions::Formatters::BatchLoaderInstanceMethods)
        end
      end

      class BatchLoadersConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

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

        def fetch(loader_name)
          opts[loader_name] || (raise SeregaError, "Batch loader with name `#{loader_name.inspect}` was not defined. Define example: config.batch_loaders.define(:#{loader_name}) { |keys, ctx, points| ... }")
        end
      end

      class BatchModel
        attr_reader :opts, :loaders, :many

        def initialize(opts, loaders, many)
          @opts = opts
          @loaders = loaders
          @many = many
        end

        def loader
          @batch_loader ||= begin
            loader = opts[:loader]
            loader = loaders.fetch(loader) if loader.is_a?(Symbol)
            loader
          end
        end

        def key
          @batch_key ||= begin
            key = opts[:key]
            key.is_a?(Symbol) ? proc { |object| object.public_send(key) } : key
          end
        end

        def default_value
          if opts.key?(:default)
            opts[:default]
          elsif many
            FROZEN_EMPTY_ARRAY
          end
        end
      end

      module ConfigInstanceMethods
        def batch_loaders
          @batch_loaders ||= BatchLoadersConfig.new(opts.fetch(:batch).fetch(:loaders))
        end
      end

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

      module CheckAttributeParamsInstanceMethods
        def check_opts
          super

          CheckOptBatch.call(opts, block)
        end
      end

      module AttributeInstanceMethods
        def batch
          opts[:batch]
        end
      end

      module MapPointInstanceMethods
        def batch
          return @batch if instance_variable_defined?(:@batch)

          @batch = begin
            opts = attribute.batch
            BatchModel.new(opts, self.class.serializer_class.config.batch_loaders, many) if opts
          end
        end
      end

      module SeregaSerializerInstanceMethods
        def initialize(**_args)
          super
          opts[:batch_loaders] = self.class.serializer_class::SeregaBatchLoaders.new
        end

        def serialize(*)
          result = super

          opts[:batch_loaders].load_all

          result
        end
      end

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
