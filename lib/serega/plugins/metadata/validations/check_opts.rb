# frozen_string_literal: true

class Serega
  module Plugins
    module Metadata
      class MetaAttribute
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
              CheckOptHideEmpty.call(opts)
              CheckOptHideNil.call(opts)
            end
          end

          extend ClassMethods
        end
      end
    end
  end
end
