# frozen_string_literal: true

require "forwardable"

class Serega
  #
  # Core class that stores serializer configuration
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

    module SeregaConfigInstanceMethods
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

      def plugins
        opts.fetch(:plugins)
      end

      def initiate_keys
        opts.fetch(:initiate_keys)
      end

      def attribute_keys
        opts.fetch(:attribute_keys)
      end

      def serialize_keys
        opts.fetch(:serialize_keys)
      end

      def check_initiate_params
        opts.fetch(:check_initiate_params)
      end

      def check_initiate_params=(value)
        raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
        opts[:check_initiate_params] = value
      end

      def max_cached_map_per_serializer_count
        opts.fetch(:max_cached_map_per_serializer_count)
      end

      def max_cached_map_per_serializer_count=(value)
        raise SeregaError, "Must have Integer value, #{value.inspect} provided" unless value.is_a?(Integer)
        opts[:max_cached_map_per_serializer_count] = value
      end

      def to_json
        opts.fetch(:to_json)
      end

      def to_json=(value)
        opts[:to_json] = value
      end

      def from_json
        opts.fetch(:from_json)
      end

      def from_json=(value)
        opts[:from_json] = value
      end
    end

    include SeregaConfigInstanceMethods
    extend Serega::SeregaHelpers::SerializerClassHelper
  end
end
