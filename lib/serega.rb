# frozen_string_literal: true

require_relative "serega/version"

# Parent class for your serializers
class Serega
  # A generic exception Serega uses.
  class Error < StandardError; end

  # @return [Hash] frozen hash
  FROZEN_EMPTY_HASH = {}.freeze

  # @return [Array] frozen array
  FROZEN_EMPTY_ARRAY = [].freeze
end

require_relative "serega/helpers/serializer_class_helper"
require_relative "serega/utils/enum_deep_dup"
require_relative "serega/utils/to_hash"
require_relative "serega/utils/to_json"
require_relative "serega/utils/as_json"

require_relative "serega/attribute"
require_relative "serega/validations/check_allowed_keys"
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
  @config = Config.new(
    {
      plugins: [],
      initiate_keys: %i[only with except],
      attribute_keys: %i[key value serializer many hide],
      serialize_keys: %i[context many],
      max_cached_map_per_serializer_count: 50,
      to_json: ->(data) { Utils::ToJSON.call(data) }
    }
  )

  # Core serializer class methods
  module ClassMethods
    # @return [Config] current serializer config
    attr_reader :config

    private def inherited(subclass)
      config_class = Class.new(self::Config)
      config_class.serializer_class = subclass
      subclass.const_set(:Config, config_class)
      subclass.instance_variable_set(:@config, subclass::Config.new(config.opts))

      attribute_class = Class.new(self::Attribute)
      attribute_class.serializer_class = subclass
      subclass.const_set(:Attribute, attribute_class)

      map_class = Class.new(self::Map)
      map_class.serializer_class = subclass
      subclass.const_set(:Map, map_class)

      convert_class = Class.new(self::Convert)
      convert_class.serializer_class = subclass
      subclass.const_set(:Convert, convert_class)

      convert_item_class = Class.new(self::ConvertItem)
      convert_item_class.serializer_class = subclass
      subclass.const_set(:ConvertItem, convert_item_class)

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
      raise Error, "This plugin is already loaded" if plugin_used?(name)

      plugin = Plugins.find_plugin(name)

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
    # @return [Serega::Attribute] Added attribute
    #
    def attribute(name, **opts, &block)
      self::Attribute.new(name: name, opts: opts, block: block).tap do |attribute|
        attributes[attribute.name] = attribute
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
    # @return [Serega::Attribute] Added attribute
    #
    def relation(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end

    def to_h(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config[:initiate_keys]
      new(opts.slice(*initiate_keys)).to_h(object, opts.except(*initiate_keys))
    end

    def to_json(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config[:initiate_keys]
      new(opts.slice(*initiate_keys)).to_json(object, opts.except(*initiate_keys))
    end

    def as_json(object, opts = FROZEN_EMPTY_HASH)
      initiate_keys = config[:initiate_keys]
      new(opts.slice(*initiate_keys)).as_json(object, opts.except(*initiate_keys))
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
      CheckAllowedKeys.call(opts, self.class.config[:initiate_keys])
      opts = prepare_modifiers(opts) if opts && (opts != FROZEN_EMPTY_HASH)
      @opts = opts
    end

    #
    # Serializes provided object to hash
    #
    # @param object [Object] Serialized object
    # @param opts [Hash] Serialization options, like :context and :many
    #
    # @return [Hash] Serialization result
    #
    def to_h(object, opts = FROZEN_EMPTY_HASH)
      CheckAllowedKeys.call(opts, self.class.config[:serialize_keys])
      self.class::Convert.call(object, **opts, map: map)
    end

    #
    # Serializes provided object to json
    #
    # @param object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def to_json(object, opts = FROZEN_EMPTY_HASH)
      hash = to_h(object, opts)
      self.class.config[:to_json].call(hash)
    end

    #
    # Serializes provided object as json (uses only JSON-compatible types)
    # When you later serialize/deserialize it from JSON you should receive
    # equal object
    #
    # @param object [Object] Serialized object
    #
    # @return [Hash] Serialization result
    #
    def as_json(object, opts = FROZEN_EMPTY_HASH)
      hash = to_h(object, opts)
      Utils::AsJSON.call(hash, to_json: self.class.config[:to_json])
    end

    private

    def map
      @map ||= self.class::Map.call(opts)
    end

    def prepare_modifiers(opts)
      {
        only: Utils::ToHash.call(opts[:only]),
        except: Utils::ToHash.call(opts[:except]),
        with: Utils::ToHash.call(opts[:with])
      }
    end
  end

  extend ClassMethods
  include InstanceMethods
end
