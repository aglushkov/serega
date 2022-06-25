# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOptMany
      module ClassMethods
        #
        # Checks attribute :many option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        def call(opts)
          return unless opts.key?(:many)

          value = opts[:many]
          return if (value == true) || (value == false)

          raise Error, "Invalid option :many => #{value.inspect}. Must have a boolean value"
        end
      end

      extend ClassMethods
    end
  end
end
