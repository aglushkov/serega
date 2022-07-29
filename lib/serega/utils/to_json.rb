# frozen_string_literal: true

class Serega
  module SeregaUtils
    class ToJSON
      class << self
        def call(data)
          json_adapter.dump(data)
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
