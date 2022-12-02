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
require_relative "serega/json/adapter"

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
require_relative "serega/object_serializer"
require_relative "serega/serializer"
require_relative "serega/map_point"
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

  #
  # Serializers class methods
  #
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

      map_point_class = Class.new(self::SeregaMapPoint)
      map_point_class.serializer_class = subclass
      subclass.const_set(:SeregaMapPoint, map_point_class)

      serega_serializer_class = Class.new(self::SeregaSerializer)
      serega_serializer_class.serializer_class = subclass
      subclass.const_set(:SeregaSerializer, serega_serializer_class)

      object_serializer_class = Class.new(self::SeregaObjectSerializer)
      object_serializer_class.serializer_class = subclass
      subclass.const_set(:SeregaObjectSerializer, object_serializer_class)

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
    # @return [Boolean] Is plugin used
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

    #
    # Serializes provided object to Hash
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Array, Hash, String, Symbol] :only The only attributes to serialize
    # @option opts [Array, Hash, String, Symbol] :except Attributes to hide
    # @option opts [Array, Hash, String, Symbol] :with Attributes (usually hidden) to serialize additionally
    # @option opts [Boolean] :validate Validates provided modifiers (Default is true)
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [Hash] Serialization result
    #
    def call(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config.initiate_keys
      new(opts.slice(*initiate_keys)).to_h(object, opts.except(*initiate_keys))
    end

    # @see #call
    def to_h(object, opts = FROZEN_EMPTY_HASH)
      call(object, opts)
    end

    #
    # Serializes provided object to JSON string
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Array, Hash, String, Symbol] :only The only attributes to serialize
    # @option opts [Array, Hash, String, Symbol] :except Attributes to hide
    # @option opts [Array, Hash, String, Symbol] :with Attributes (usually hidden) to serialize additionally
    # @option opts [Boolean] :validate Validates provided modifiers (Default is true)
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [String] Serialization result
    #
    def to_json(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config.initiate_keys
      new(opts.slice(*initiate_keys)).to_json(object, opts.except(*initiate_keys))
    end

    #
    # Serializes provided object as JSON
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Array, Hash, String, Symbol] :only The only attributes to serialize
    # @option opts [Array, Hash, String, Symbol] :except Attributes to hide
    # @option opts [Array, Hash, String, Symbol] :with Attributes (usually hidden) to serialize additionally
    # @option opts [Boolean] :validate Validates provided modifiers (Default is true)
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [Hash] Serialization result
    #
    def as_json(object, opts = FROZEN_EMPTY_HASH)
      config.from_json.call(to_json(object, opts))
    end
  end

  #
  # Serializers instance methods
  #
  module InstanceMethods
    #
    # Instantiates new Serega class
    #
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Array, Hash, String, Symbol] :only The only attributes to serialize
    # @option opts [Array, Hash, String, Symbol] :except Attributes to hide
    # @option opts [Array, Hash, String, Symbol] :with Attributes (usually hidden) to serialize additionally
    # @option opts [Boolean] :validate Validates provided modifiers (Default is true)
    #
    def initialize(opts = FROZEN_EMPTY_HASH)
      @opts = (opts == FROZEN_EMPTY_HASH) ? opts : prepare_modifiers(opts)
      self.class::CheckInitiateParams.new(@opts).validate if opts.fetch(:check_initiate_params) { config.check_initiate_params }
    end

    #
    # Serializes provided object to Hash
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [Hash] Serialization result
    #
    def call(object, opts = {})
      self.class::CheckSerializeParams.new(opts).validate
      opts[:context] ||= {}

      self.class::SeregaSerializer.new(serializer: self, **opts).serialize(object)
    end

    # @see #call
    def to_h(object, opts = {})
      call(object, opts)
    end

    #
    # Serializes provided object to JSON string
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [Hash] Serialization result
    #
    def to_json(object, opts = {})
      hash = to_h(object, opts)
      config.to_json.call(hash)
    end

    #
    # Serializes provided object as JSON
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serializer modifiers and other instantiating options
    # @option opts [Hash] :context Serialization context
    # @option opts [Boolean] :many Set true if provided multiple objects (Default `object.is_a?(Enumerable)`)
    #
    # @return [Hash] Serialization result
    #
    def as_json(object, opts = {})
      json = to_json(object, opts)
      config.from_json.call(json)
    end

    #
    # Array of MapPoints, which are attributes combined with nested attributes.
    # This map can be traversed to find currently serializing attributes.
    #
    # @return [Array<Serega::SeregaMapPoint>] map
    def map
      @map ||= self.class::SeregaMap.call(opts)
    end

    private

    attr_reader :opts

    def config
      self.class.config
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
