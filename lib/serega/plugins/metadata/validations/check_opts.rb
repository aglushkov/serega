# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class MetaAttribute
        class CheckOpts
          class << self
            #
            # Validates attribute options
            # Checks used options are allowed and then checks options values.
            #
            # @param opts [Hash] Attribute options
            # @param attribute_keys [Array<Symbol>] Allowed options keys
            #
            # @raise [SeregaError] when attribute has invalid options
            #
            # @return [void]
            #
            def call(opts, attribute_keys)
              opts.each_key do |key|
                next if attribute_keys.include?(key.to_sym)

                raise SeregaError, "Invalid option #{key.inspect}. Allowed options are: #{attribute_keys.map(&:inspect).join(", ")}"
              end

              check_each_opt(opts)
            end

            private

            def check_each_opt(opts)
              CheckOptHideEmpty.call(opts)
              CheckOptHideNil.call(opts)
            end
          end
        end
      end
    end
  end
end
