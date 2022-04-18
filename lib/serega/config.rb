# frozen_string_literal: true

require "forwardable"

class Serega
  #
  # Core class that stores serializer configuration
  #
  class SeregaConfig
    module SeregaConfigInstanceMethods
      extend Forwardable

      # @return [Hash] Current config data
      attr_reader :opts

      #
      # Initializes new config instance and deeply duplicates all provided options to
      # remove possibility of accidental overwriting of parent/nested configs.
      #
      # @param opts [Hash] Initial config options
      #
      def initialize(opts = {})
        @opts = SeregaUtils::SeregaEnumDeepDup.call(opts)
      end

      #
      # @!method [](name)
      #   Get config option, delegates to opts#[]
      #   @param name [Symbol] option name
      #   @return [Object]
      #
      # @!method []=(name)
      #   Set config option, delegates to opts#[]=
      #   @param name [Symbol] option name
      #   @return [Object]
      #
      # @!method fetch(name)
      #   Fetch config option, delegates to opts#fetch
      #   @param name [Symbol] option name
      #   @return [Object]
      #
      def_delegators :opts, :[], :[]=, :fetch, :keys, :has_key?
    end

    include SeregaConfigInstanceMethods
    extend Serega::SeregaHelpers::SeregaSerializerClassHelper
  end
end
