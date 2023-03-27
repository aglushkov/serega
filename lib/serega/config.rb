# frozen_string_literal: true

require "forwardable"

class Serega
  #
  # Stores serialization config
  #
  class SeregaConfig
    # :nocov: We can't use both :oj and :json adapters together

    #
    # Default config options
    #
    DEFAULTS = {
      plugins: [],
      initiate_keys: %i[only with except check_initiate_params].freeze,
      attribute_keys: %i[key value serializer many hide const delegate].freeze,
      serialize_keys: %i[context many].freeze,
      check_attribute_name: true,
      check_initiate_params: true,
      max_cached_map_per_serializer_count: 0,
      to_json: (SeregaJSON.adapter == :oj) ? SeregaJSON::OjDump : SeregaJSON::JSONDump,
      from_json: (SeregaJSON.adapter == :oj) ? SeregaJSON::OjLoad : SeregaJSON::JSONLoad
    }.freeze
    # :nocov:

    # SeregaConfig Instance methods
    module SeregaConfigInstanceMethods
      #
      # Shows current config as Hash
      #
      # @return [Hash] config options
      #
      attr_reader :opts

      #
      # Initializes new config instance.
      #
      # @param opts [Hash] Initial config options
      #
      def initialize(opts = nil)
        opts ||= DEFAULTS
        @opts = SeregaUtils::EnumDeepDup.call(opts)
      end

      #
      # Shows used plugins
      #
      # @return [Array] Used plugins
      #
      def plugins
        opts.fetch(:plugins)
      end

      # Returns options names allowed in `Serega#new` method
      # @return [Array<Symbol>] allowed options keys
      def initiate_keys
        opts.fetch(:initiate_keys)
      end

      # Returns options names allowed in `Serega.attribute` method
      # @return [Array<Symbol>] Allowed options keys for attribute initialization
      def attribute_keys
        opts.fetch(:attribute_keys)
      end

      # Returns options names allowed in `to_h, to_json, as_json` methods
      # @return [Array<Symbol>] Allowed options keys for serialization
      def serialize_keys
        opts.fetch(:serialize_keys)
      end

      # Returns :check_initiate_params config option
      # @return [Boolean] Current :check_initiate_params config option
      def check_initiate_params
        opts.fetch(:check_initiate_params)
      end

      # Sets :check_initiate_params config option
      #
      # @param value [Boolean] Set :check_initiate_params config option
      #
      # @return [Boolean] :check_initiate_params config option
      def check_initiate_params=(value)
        raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
        opts[:check_initiate_params] = value
      end

      # Returns :max_cached_map_per_serializer_count config option
      # @return [Boolean] Current :max_cached_map_per_serializer_count config option
      def max_cached_map_per_serializer_count
        opts.fetch(:max_cached_map_per_serializer_count)
      end

      # Sets :max_cached_map_per_serializer_count config option
      #
      # @param value [Boolean] Set :check_initiate_params config option
      #
      # @return [Boolean] New :max_cached_map_per_serializer_count config option
      def max_cached_map_per_serializer_count=(value)
        raise SeregaError, "Must have Integer value, #{value.inspect} provided" unless value.is_a?(Integer)
        opts[:max_cached_map_per_serializer_count] = value
      end

      # Returns whether attributes names check is disabled
      def check_attribute_name
        opts.fetch(:check_attribute_name)
      end

      # Sets :check_attribute_name config option
      #
      # @param value [Boolean] Set :check_attribute_name config option
      #
      # @return [Boolean] New :check_attribute_name config option
      def check_attribute_name=(value)
        raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
        opts[:check_attribute_name] = value
      end

      # Returns current `to_json` adapter
      # @return [#call] Callable that used to construct JSON
      def to_json
        opts.fetch(:to_json)
      end

      # Sets current `to_json` adapter
      # @param value [#call] Callable that used to construct JSON
      # @return [#call] Provided callable object
      def to_json=(value)
        opts[:to_json] = value
      end

      # Returns current `from_json` adapter
      # @return [#call] Callable that used to parse JSON
      def from_json
        opts.fetch(:from_json)
      end

      # Sets current `from_json` adapter
      # @param value [#call] Callable that used to parse JSON
      # @return [#call] Provided callable object
      def from_json=(value)
        opts[:from_json] = value
      end
    end

    include SeregaConfigInstanceMethods
    extend Serega::SeregaHelpers::SerializerClassHelper
  end
end
