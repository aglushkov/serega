# frozen_string_literal: true

class Serega
  module SeregaValidations
    module SeregaUtils
      class CheckAllowedKeys
        def self.call(opts, allowed_keys)
          opts.each_key do |key|
            next if allowed_keys.include?(key)

            raise SeregaError, "Invalid option #{key.inspect}. Allowed options are: #{allowed_keys.map(&:inspect).join(", ")}"
          end
        end
      end
    end
  end
end
