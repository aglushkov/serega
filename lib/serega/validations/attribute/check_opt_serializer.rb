# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOptSerializer
      module ClassMethods
        #
        # Checks attribute :serializer option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        def call(opts)
          return unless opts.key?(:serializer)

          value = opts[:serializer]
          return if valid_serializer?(value)

          raise Error, "Invalid option :serializer => #{value.inspect}." \
            " Can be a Serega subclass, a String or a Proc without arguments"
        end

        private

        def valid_serializer?(value)
          value.is_a?(String) ||
            (value.is_a?(Proc) && (value.parameters.count == 0)) ||
            (value.is_a?(Class) && (value < Serega))
        end
      end

      extend ClassMethods
    end
  end
end
