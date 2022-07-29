# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class MetaAttribute
        class CheckOptHideNil
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
              return unless opts.key?(:hide_nil)

              value = opts[:hide_nil]
              return if value == true

              raise Error, "Invalid option :hide_nil => #{value.inspect}. Must be true"
            end
          end
        end
      end
    end
  end
end
