# frozen_string_literal: true

class Serega
  module SeregaUtils
    #
    # Utility to get frozen string from symbol in any ruby version
    #
    class SymbolName
      class << self
        if RUBY_VERSION < "3"
          #
          # Returns symbol string name
          #
          # @param key [Symbol]
          #
          # @return frozen string corresponding to provided symbol
          #
          def call(key)
            key.name
          end
        else
          #
          # Returns symbol string name
          #
          # @param key [Symbol]
          #
          # @return frozen string corresponding to provided symbol
          #
          # :nocov:
          def call(key)
            key.to_s.freeze
          end
          # :nocov:
        end
      end
    end
  end
end
