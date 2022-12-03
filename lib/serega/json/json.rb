# frozen_string_literal: true

class Serega
  module SeregaJSON
    #
    # JSON dump adapter for ::JSON
    #
    class JSONDump
      #
      # Dumps data to JSON string
      #
      # @param data [Object] Anything
      #
      # @return [String] Data serialized to JSON
      #
      def self.call(data)
        ::JSON.dump(data)
      end
    end

    #
    # JSON parse adapter for ::JSON
    #
    class JSONLoad
      #
      # Loads object from JSON string
      #
      # @param json_string [String] JSON String
      #
      # @return [Object] Deserialized data
      #
      def self.call(json_string)
        ::JSON.parse(json_string)
      end
    end
  end
end
