# frozen_string_literal: true

class Serega
  module SeregaUtils
    #
    # Utility to get frozen string from symbol in any ruby version
    #
    class SymbolName
      class << self
        #
        # Returns frozen string corresponding to provided symbol
        #
        # @param key [Symbol]
        #
        # @return [String] frozen string corresponding to provided symbol
        #
        def call(key)
          if key.is_a?(Symbol)
            to_frozen_string(key)
          else
            key.dedup
          end
        end

        private

        # :nocov:
        if RUBY_VERSION < "3"
          def to_frozen_string(key)
            key.to_s.dedup
          end
        else
          def to_frozen_string(key)
            key.name
          end
        end
        # :nocov:
      end
    end
  end
end
