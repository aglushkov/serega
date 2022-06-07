# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOptHide
      module ClassMethods
        #
        # Checks attribute :hide option
        #
        # @param opts [Hash] Attribute options
        #
        # @raise [Error] Error that option has invalid value
        #
        # @return [void]
        #
        def call(opts)
          return unless opts.key?(:hide)

          value = opts[:hide]
          return if (value == true) || (value == false)

          raise Error, "Invalid option :hide => #{value.inspect}. Must have a boolean value"
        end
      end

      extend ClassMethods
    end
  end
end
