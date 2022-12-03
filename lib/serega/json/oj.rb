# frozen_string_literal: true

class Serega
  module SeregaJSON
    #
    # JSON dump adapter for ::Oj
    #
    class OjDump
      #
      # Dumps data to JSON string
      #
      # @param data [Object] Anything
      #
      # @return [String] Data serialized to JSON
      #
      def self.call(data)
        ::Oj.dump(data, mode: :compat)
      end
    end

    #
    # JSON parse adapter for ::Oj
    #
    class OjLoad
      #
      # Loads object from JSON string
      #
      # @param json_string [String] JSON String
      #
      # @return [Object] Deserialized data
      #
      def self.call(json_string)
        ::Oj.load(json_string)
      end
    end
  end
end
