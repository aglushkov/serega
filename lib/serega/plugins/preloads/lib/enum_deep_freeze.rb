# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Utility to freeze nested hashes and arrays
      #
      class EnumDeepFreeze
        class << self
          #
          # Freezes nested hashes and arrays
          #
          # @param data[Hash, Array] data to freeze
          #
          # @return [Hash, Array] same deeply frozen data
          #
          def call(data)
            case data
            when Hash
              data.transform_values! { |value| call(value) }
            when Array
              data.map! { |value| call(value) }
            end

            data.freeze
          end
        end
      end
    end
  end
end
