# frozen_string_literal: true

require_relative "serega/version"

# Parent class for your serializers
class Serega
  # @return [Hash] frozen hash
  FROZEN_EMPTY_HASH = {}.freeze

  # @return [Array] frozen array
  FROZEN_EMPTY_ARRAY = [].freeze
end

require_relative "serega/errors"
require_relative "serega/helpers/serializer_class_helper"
require_relative "serega/utils/enum_deep_dup"
require_relative "serega/utils/to_hash"
require_relative "serega/utils/json"

require_relative "serega/attribute"
require_relative "serega/validations/utils/check_allowed_keys"
require_relative "serega/validations/utils/check_opt_is_bool"
require_relative "serega/validations/utils/check_opt_is_hash"
require_relative "serega/validations/utils/check_opt_is_string_or_symbol"
require_relative "serega/validations/attribute/check_block"
require_relative "serega/validations/attribute/check_name"
require_relative "serega/validations/attribute/check_opt_const"
require_relative "serega/validations/attribute/check_opt_hide"
require_relative "serega/validations/attribute/check_opt_delegate"
require_relative "serega/validations/attribute/check_opt_key"
require_relative "serega/validations/attribute/check_opt_many"
require_relative "serega/validations/attribute/check_opt_serializer"
require_relative "serega/validations/attribute/check_opt_value"
require_relative "serega/validations/initiate/check_modifiers"
require_relative "serega/validations/check_attribute_params"
require_relative "serega/validations/check_initiate_params"
require_relative "serega/validations/check_serialize_params"

require_relative "serega/config"
require_relative "serega/convert"
require_relative "serega/convert_item"
require_relative "serega/map"
require_relative "serega/plugins"

class Serega
  @config = SeregaConfig.new

  # Validates `Serializer.attribute` params
  check_attribute_params_class = Class.new(SeregaValidations::CheckAttributeParams)
  check_attribute_params_class.serializer_class = self
  const_set(:CheckAttributeParams, check_attribute_params_class)

  # Validates `Serializer#new` params
  check_initiate_params_class = Class.new(SeregaValidations::CheckInitiateParams)
  check_initiate_params_class.serializer_class = self
  const_set(:CheckInitiateParams, check_initiate_params_class)

  # Validates `serializer#call(obj, PARAMS)` params
  check_serialize_params_class = Class.new(SeregaValidations::CheckSerializeParams)
  check_serialize_params_class.serializer_class = self
  const_set(:CheckSerializeParams, check_serialize_params_class)

  # Core serializer class methods
  module ClassMethods
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

      check_attribute_params_class = Class.new(self::CheckAttributeParams)
      check_attribute_params_class.serializer_class = subclass
      subclass.const_set(:CheckAttributeParams, check_attribute_params_class)

      check_initiate_params_class = Class.new(self::CheckInitiateParams)
      check_initiate_params_class.serializer_class = subclass
      subclass.const_set(:CheckInitiateParams, check_initiate_params_class)

      check_serialize_params_class = Class.new(self::CheckSerializeParams)
      check_serialize_params_class.serializer_class = subclass
      subclass.const_set(:CheckSerializeParams, check_serialize_params_class)

      # Assign same attributes
      attributes.each_value do |attr|
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
      config.plugins << (plugin.respond_to?(:plugin_name) ? plugin.plugin_name : plugin)

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

      config.plugins.include?(plugin_name)
    end

    #
    # Lists attributes
    #
    # @return [Hash] attributes list
    #
    def attributes
      @attributes ||= {}
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
      attribute = self::SeregaAttribute.new(name: name, opts: opts, block: block)
      attributes[attribute.name] = attribute
    end

    def call(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config.initiate_keys
      new(opts.slice(*initiate_keys)).to_h(object, opts.except(*initiate_keys))
    end

    def to_h(object, opts = FROZEN_EMPTY_HASH)
      call(object, opts)
    end

    def to_json(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config.initiate_keys
      new(opts.slice(*initiate_keys)).to_json(object, opts.except(*initiate_keys))
    end

    def as_json(object, opts = FROZEN_EMPTY_HASH)
      config.from_json.call(to_json(object, opts))
    end
  end

  #
  # Core serializer instance methods
  #
  module InstanceMethods
    attr_reader :opts

    #
    # Instantiates new Serega class
    #
    # @param only [Array, Hash, String, Symbol] The only attributes to serialize
    # @param except [Array, Hash, String, Symbol] Attributes to hide
    # @param with [Array, Hash, String, Symbol] Attributes (usually hidden) to serialize additionally
    #
    def initialize(opts = FROZEN_EMPTY_HASH)
      @opts = opts == FROZEN_EMPTY_HASH ? opts : prepare_modifiers(opts)
      self.class::CheckInitiateParams.new(@opts).validate if opts.fetch(:check_initiate_params) { config.check_initiate_params }
    end

    #
    # Serializes provided object to hash
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serialization options, like :context and :many
    #
    # @return [Hash] Serialization result
    #
    def call(object, opts = {})
      self.class::CheckSerializeParams.new(opts).validate
      opts[:context] ||= {}

      self.class::SeregaConvert.call(object, **opts, map: map)
    end

    # @see #call
    def to_h(object, opts = {})
      call(object, opts)
    end

    #
    # Serializes provided object to json
    #
    # @param object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def to_json(object, opts = {})
      hash = to_h(object, opts)
      config.to_json.call(hash)
    end

    #
    # Serializes provided object as json (uses only JSON-compatible types)
    # When you later serialize/de-serialize it from JSON you should receive
    # equal object
    #
    # @param object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def as_json(object, opts = {})
      json = to_json(object, opts)
      config.from_json.call(json)
    end

    private

    def config
      self.class.config
    end

    def map
      @map ||= self.class::SeregaMap.call(opts)
    end

    def prepare_modifiers(opts)
      opts.each_with_object({}) do |(key, value), obj|
        value = SeregaUtils::ToHash.call(value) if (key == :only) || (key == :except) || (key == :with)
        obj[key] = value
      end
    end
  end

  extend ClassMethods
  include InstanceMethods
end
