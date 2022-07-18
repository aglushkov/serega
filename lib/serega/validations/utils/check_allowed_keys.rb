# frozen_string_literal: true

class Serega
  module Validations
    module Utils
      class CheckAllowedKeys
        def self.call(opts, allowed_keys)
          opts.each_key do |key|
            next if allowed_keys.include?(key)

            raise Error, "Invalid option #{key.inspect}. Allowed options are: #{allowed_keys.map(&:inspect).join(", ")}"
          end
        end
      end
    end
  end
end
