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
          # Freezes nested enumerable data
          #
          # @param data[Hash, Array] data to freeze
          #
          # @return [Hash, Array] same deeply frozen data
          #
          def call(data)
            data.each_entry { |entry| call(entry) } if data.is_a?(Enumerable)
            data.freeze
          end
        end
      end
    end
  end
end
