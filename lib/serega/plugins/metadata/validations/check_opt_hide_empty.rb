# frozen_string_literal: true

class Serega
  module Plugins
    module Metadata
      class MetaAttribute
        class CheckOptHideEmpty
          class << self
            #
            # Checks attribute :after_hide_if option
            #
            # @param opts [Hash] Attribute options
            #
            # @raise [Error] Error that option has invalid value
            #
            # @return [void]
            #
            def call(opts)
              return unless opts.key?(:hide_empty)

              value = opts[:hide_empty]
              return if value == true

              raise Error, "Invalid option :hide_empty => #{value.inspect}. Must be true"
            end
          end
        end
      end
    end
  end
end
