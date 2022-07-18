# frozen_string_literal: true

class Serega
  module Validations
    module Utils
      class CheckOptIsBool
        def self.call(opts, key)
          return unless opts.key?(key)

          value = opts[key]
          return if value.equal?(true) || value.equal?(false)

          raise Error, "Invalid option #{key.inspect} => #{value.inspect}. Must have a boolean value"
        end
      end
    end
  end
end
