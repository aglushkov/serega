# frozen_string_literal: true

require "forwardable"

class Serega
  #
  # Stores serialization config
  #
  class SeregaConfig
    # :nocov: We can't use both :oj and :json adapters together
    DEFAULTS = {
      plugins: [],
      initiate_keys: %i[only with except check_initiate_params].freeze,
      attribute_keys: %i[key value serializer many hide const delegate].freeze,
      serialize_keys: %i[context many].freeze,
      check_initiate_params: true,
      max_cached_map_per_serializer_count: 0,
      to_json: (SeregaJSON.adapter == :oj) ? SeregaJSON::OjDump : SeregaJSON::JSONDump,
      from_json: (SeregaJSON.adapter == :oj) ? SeregaJSON::OjLoad : SeregaJSON::JSONLoad
    }.freeze
    # :nocov:

    # SeregaConfig Instance methods
    module SeregaConfigInstanceMethods
      #
      # @return [Hash] All config options
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

      # @return [Array] Used plugins
      def plugins
        opts.fetch(:plugins)
      end

      # @return [Array<Symbol>] Allowed options keys for serializer initialization
      def initiate_keys
        opts.fetch(:initiate_keys)
      end

      # @return [Array<Symbol>] Allowed options keys for attribute initialization
      def attribute_keys
        opts.fetch(:attribute_keys)
      end

      # @return [Array<Symbol>] Allowed options keys for serialization
      def serialize_keys
        opts.fetch(:serialize_keys)
      end

      # @return [Boolean] Current :check_initiate_params config option
      def check_initiate_params
        opts.fetch(:check_initiate_params)
      end

      # @param value [Boolean] Set :check_initiate_params config option
      #
      # @return [Boolean] :check_initiate_params config option
      def check_initiate_params=(value)
        raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
        opts[:check_initiate_params] = value
      end

      # @return [Boolean] Current :max_cached_map_per_serializer_count config option
      def max_cached_map_per_serializer_count
        opts.fetch(:max_cached_map_per_serializer_count)
      end

      # @param value [Boolean] Set :check_initiate_params config option
      #
      # @return [Boolean] New :max_cached_map_per_serializer_count config option
      def max_cached_map_per_serializer_count=(value)
        raise SeregaError, "Must have Integer value, #{value.inspect} provided" unless value.is_a?(Integer)
        opts[:max_cached_map_per_serializer_count] = value
      end

      # @return [#call] Callable that used to construct JSON
      def to_json
        opts.fetch(:to_json)
      end

      # @param value [#call] Callable that used to construct JSON
      # @return [#call] Provided callable object
      def to_json=(value)
        opts[:to_json] = value
      end

      # @return [#call] Callable that used to parse JSON
      def from_json
        opts.fetch(:from_json)
      end

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
