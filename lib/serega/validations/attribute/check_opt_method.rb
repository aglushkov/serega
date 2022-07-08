# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOptMethod
      #
      # Checks attribute :method option
      #
      # @param opts [Hash] Attribute options
      #
      # @raise [Error] Error that option has invalid value
      #
      # @return [void]
      #
      def self.call(opts)
        return unless opts.key?(:method)

        value = opts[:method]
        return if value.is_a?(String) || value.is_a?(Symbol)

        raise Error, "Invalid option :method => #{value.inspect}. Must be a String or a Symbol"
      end
    end
  end
end
