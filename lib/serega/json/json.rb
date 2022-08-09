# frozen_string_literal: true

class Serega
  module SeregaJSON
    class JSONDump
      def self.call(data)
        ::JSON.dump(data)
      end
    end

    class JSONLoad
      def self.call(json_string)
        ::JSON.parse(json_string)
      end
    end
  end
end
