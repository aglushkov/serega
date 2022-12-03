# frozen_string_literal: true

class Serega
  #
  # JSON adapters
  #
  module SeregaJSON
    # Current JSON adapter
    #
    # @return [Symbol] Current JSON adapter name - :oj or :json
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
