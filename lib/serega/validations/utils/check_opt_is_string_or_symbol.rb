# frozen_string_literal: true

class Serega
  module SeregaValidations
    module SeregaUtils
      class CheckOptIsStringOrSymbol
        def self.call(opts, key)
          return unless opts.key?(key)

          value = opts[key]
          return if value.is_a?(String) || value.is_a?(Symbol)

          raise SeregaError, "Invalid option #{key.inspect} => #{value.inspect}. Must be a String or a Symbol"
        end
      end
    end
  end
end
