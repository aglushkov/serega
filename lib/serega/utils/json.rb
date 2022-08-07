# frozen_string_literal: true

class Serega
  module SeregaUtils
    class JSON
      class << self
        def dump(data)
          json_adapter.dump(data)
        end

        def load(data)
          json_adapter.load(data)
        end

        private

        def json_adapter
          @json_adapter ||= begin
            require "json"
            ::JSON
          end
        end
      end
    end
  end
end
