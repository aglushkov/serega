# frozen_string_literal: true

class Serega
  module Validations
    module Utils
      class CheckOptIsStringOrSymbol
        def self.call(opts, key)
          return unless opts.key?(key)

          value = opts[key]
          return if value.is_a?(String) || value.is_a?(Symbol)

          raise Error, "Invalid option #{key.inspect} => #{value.inspect}. Must be a String or a Symbol"
        end
      end
    end
  end
end
