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
        # @param allowed_opts [Array<Symbol>] Allowed options keys
        #
        # @raise [Error] when attribute has invalid options
        #
        # @return [void]
        #
        def call(opts, allowed_opts)
          opts.each_key do |key|
            next if allowed_opts.include?(key.to_sym)

            raise Error, "Invalid option #{key.inspect}. Allowed options are: #{allowed_opts.map(&:inspect).join(", ")}"
          end

          check_each_opt(opts)
        end

        private

        def check_each_opt(opts)
          CheckOptHide.call(opts)
          CheckOptKey.call(opts)
          CheckOptMany.call(opts)
          CheckOptSerializer.call(opts)
        end
      end

      extend ClassMethods
    end
  end
end
