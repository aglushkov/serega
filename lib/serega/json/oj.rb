# frozen_string_literal: true

class Serega
  module SeregaJSON
    class OjDump
      def self.call(data)
        ::Oj.dump(data, mode: :compat)
      end
    end

    class OjLoad
      def self.call(json_string)
        ::Oj.load(json_string)
      end
    end
  end
end
