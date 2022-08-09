# frozen_string_literal: true

class Serega
  module SeregaJSON
    def self.adapter
      @adapter ||=
        if defined?(::Oj)
          require_relative "oj"
          :oj
        else
          require "json"
          require_relative "json"
          :json
        end
    end
  end
end
