# frozen_string_literal: true

class Serega
  module Plugins
    module Preloads
      # Freezes nested enumerable data
      class EnumDeepFreeze
        class << self
          def call(data)
            data.each_entry { |entry| call(entry) } if data.is_a?(Enumerable)
            data.freeze
          end
        end
      end
    end
  end
end
