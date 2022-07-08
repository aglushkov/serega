# frozen_string_literal: true

class Serega
  class Attribute
    class CheckOpts
      module ClassMethods
        #
        # Validates attribute options
        # Checks used options are allowed and then checks options values.
        #
        # @param opts [Hash] Attribute options
        # @param attribute_keys [Array<Symbol>] Allowed options keys
        #
        # @raise [Error] when attribute has invalid options
        #
        # @return [void]
        #
        def call(opts, attribute_keys)
          CheckAllowedKeys.call(opts, attribute_keys)
          check_each_opt(opts)
        end

        private

        def check_each_opt(opts)
          CheckOptHide.call(opts)
          CheckOptMethod.call(opts)
          CheckOptMany.call(opts)
          CheckOptSerializer.call(opts)
        end
      end

      extend ClassMethods
    end
  end
end
