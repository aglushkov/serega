# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class SeregaMetaAttribute
        class CheckOptHideEmpty
          module ClassMethods
            #
            # Checks attribute :after_hide_if option
            #
            # @param opts [Hash] Attribute options
            #
            # @raise [SeregaError] Error that option has invalid value
            #
            # @return [void]
            #
            def call(opts)
              return unless opts.key?(:hide_empty)

              value = opts[:hide_empty]
              return if value == true

              raise SeregaError, "Invalid option :hide_empty => #{value.inspect}. Must be true"
            end
          end

          extend ClassMethods
        end
      end
    end
  end
end
