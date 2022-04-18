# frozen_string_literal: true

require_relative "serega/version"

# Parent class for your serializers
class Serega
  # A generic exception Serega uses.
  class SeregaError < StandardError; end

  # @return [Hash] frozen hash
  FROZEN_EMPTY_HASH = {}.freeze

  # @return [Array] frozen array
  FROZEN_EMPTY_ARRAY = [].freeze
end
require_relative "serega/helpers/serializer_class_helper"
require_relative "serega/utils/enum_deep_dup"
require_relative "serega/utils/to_hash"

require_relative "serega/attribute"
require_relative "serega/validations/attribute/check_block"
require_relative "serega/validations/attribute/check_name"
require_relative "serega/validations/attribute/check_opt_hide"
require_relative "serega/validations/attribute/check_opt_key"
require_relative "serega/validations/attribute/check_opt_many"
require_relative "serega/validations/attribute/check_opt_serializer"
require_relative "serega/validations/attribute/check_opts"

require_relative "serega/config"
require_relative "serega/convert"
require_relative "serega/convert_item"
require_relative "serega/map"
require_relative "serega/plugins"

class Serega
  @config = SeregaConfig.new(
    {
      plugins: [],
      allowed_opts: %i[key serializer many hide],
      max_cached_map_per_serializer_count: 50
    }
  )

  # Core serializer class methods
  module SeregaClassMethods
    # @return [SeregaConfig] current serializer config
    attr_reader :config

    private def inherited(subclass)
      config_class = Class.new(self::SeregaConfig)
      config_class.serializer_class = subclass
      subclass.const_set(:SeregaConfig, config_class)
      subclass.instance_variable_set(:@config, subclass::SeregaConfig.new(config.opts))

      attribute_class = Class.new(self::SeregaAttribute)
      attribute_class.serializer_class = subclass
      subclass.const_set(:SeregaAttribute, attribute_class)

      map_class = Class.new(self::SeregaMap)
      map_class.serializer_class = subclass
      subclass.const_set(:SeregaMap, map_class)

      convert_class = Class.new(self::SeregaConvert)
      convert_class.serializer_class = subclass
      subclass.const_set(:SeregaConvert, convert_class)

      convert_item_class = Class.new(self::SeregaConvertItem)
      convert_item_class.serializer_class = subclass
      subclass.const_set(:SeregaConvertItem, convert_item_class)

      # Assign same attributes
      attributes.each do |attr|
        subclass.attribute(attr.name, **attr.opts, &attr.block)
      end

      super
    end

    #
    # Enables plugin for current serializer
    #
    # @param name [Symbol, Class<Module>] Plugin name or plugin module itself
    # @param opts [Hash>] Plugin options
    #
    # @return [class<Module>] Loaded plugin module
    #
    def plugin(name, **opts)
      raise SeregaError, "This plugin is already loaded" if plugin_used?(name)

      plugin = SeregaPlugins.find_plugin(name)

      # We split loading of plugin to three parts - before_load, load, after_load:
      #
      # - **before_load_plugin** usually used to check requirements and to load additional plugins
      # - **load_plugin** usually used to include plugin modules
      # - **after_load_plugin** usually used to add config options
      plugin.before_load_plugin(self, **opts) if plugin.respond_to?(:before_load_plugin)
      plugin.load_plugin(self, **opts) if plugin.respond_to?(:load_plugin)
      plugin.after_load_plugin(self, **opts) if plugin.respond_to?(:after_load_plugin)

      # Store attached plugins, so we can check it is loaded later
      config[:plugins] << (plugin.respond_to?(:plugin_name) ? plugin.plugin_name : plugin)

      plugin
    end

    #
    # Checks plugin is used
    #
    # @param name [Symbol, Class<Module>] Plugin name or plugin module itself
    #
    # @return [Boolean]
    #
    def plugin_used?(name)
      plugin_name =
        case name
        when Module then name.respond_to?(:plugin_name) ? name.plugin_name : name
        else name
        end

      config[:plugins].include?(plugin_name)
    end

    #
    # Lists attributes
    #
    # @return [Array<Serega::SeregaAttribute>] attributes list
    #
    def attributes
      @attributes ||= []
    end

    #
    # Adds attribute
    #
    # @param name [Symbol] Attribute name. Attribute value will be found by executing `object.<name>`
    # @param opts [Hash] Options to serialize attribute
    # @param block [Proc] Custom block to find attribute value. Accepts object and context.
    #
    # @return [Serega::SeregaAttribute] Added attribute
    #
    def attribute(name, **opts, &block)
      self::SeregaAttribute.new(name: name, opts: opts, block: block).tap do |attribute|
        attributes << attribute
      end
    end

    #
    # Adds relation
    #
    # @param name [Symbol] Attribute name. Attribute value will be found by executing `object.<name>`
    # @param serializer [Serega, Proc] Specifies nested serializer for relationship
    # @param opts [Hash] Options for attribute serialization
    # @param block [Proc] Custom block to find attribute value. Accepts object and context.
    #
    # @return [Serega::SeregaAttribute] Added attribute
    #
    def relation(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end
  end

  #
  # Core serializer instance methods
  #
  module SeregaInstanceMethods
    attr_reader :context

    #
    # Instantiates new Serega class. It will be more effective to call this manually if context is constant.
    #
    # @param context [Hash] Serialization context
    #
    def initialize(context = {})
      @context = context
    end

    #
    # Serializes provided object to hash
    #
    # @param object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def to_h(object)
      self.class::SeregaConvert.call(object, context, map)
    end

    def map
      @map ||= begin
        only = SeregaUtils::SeregaToHash.call(context[:only])
        except = SeregaUtils::SeregaToHash.call(context[:except])
        with = SeregaUtils::SeregaToHash.call(context[:with])

        self.class::SeregaMap.call(only: only, except: except, with: with)
      end
    end
  end

  extend SeregaClassMethods
  include SeregaInstanceMethods
end
