# frozen_string_literal: true

class Serega
  module Utils
    class AsJSON
      DOUBLE_QUOTE = '"'

      class << self
        def call(data, to_json:)
          case data
          when Hash
            data.each_with_object({}) do |(key, value), new_data|
              new_key = key.to_s
              new_value = call(value, to_json: to_json)
              new_data[new_key] = new_value
            end
          when Array
            data.map { |value| call(value, to_json: to_json) }
          when NilClass, Integer, Float, String, TrueClass, FalseClass
            data
          when Symbol
            data.to_s
          else
            res = to_json.call(data)
            if res.start_with?(DOUBLE_QUOTE) && res.end_with?(DOUBLE_QUOTE)
              res.delete_prefix!(DOUBLE_QUOTE)
              res.delete_suffix!(DOUBLE_QUOTE)
            end
            res
          end
        end
      end
    end
  end
end
