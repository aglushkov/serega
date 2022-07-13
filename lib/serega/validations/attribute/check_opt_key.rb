# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOptKey
      #
      # Checks attribute :key option
      #
      # @param opts [Hash] Attribute options
      #
      # @raise [Error] Error that option has invalid value
      #
      # @return [void]
      #
      def self.call(opts)
        return unless opts.key?(:key)

        value = opts[:key]
        return if value.is_a?(String) || value.is_a?(Symbol)

        raise Error, "Invalid option :key => #{value.inspect}. Must be a String or a Symbol"
      end
    end
  end
end
