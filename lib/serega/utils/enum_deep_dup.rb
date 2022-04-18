# frozen_string_literal: true

class Serega
  module SeregaUtils
    # Duplicates nested hashes and arrays
    class SeregaEnumDeepDup
      DUP = {
        Hash => ->(data) { dup_hash_values(data) },
        Array => ->(data) { dup_array_values(data) }
      }.freeze
      private_constant :DUP

      class << self
        #
        # Deeply duplicate provided data
        #
        # @param data [Hash, Array] Data to duplicate
        #
        # @return [Hash, Array] Duplicated data
        #
        def call(data)
          duplicate_data = data.dup
          DUP.fetch(duplicate_data.class).call(duplicate_data)
          duplicate_data
        end

        private

        def dup_hash_values(duplicate_data)
          duplicate_data.each do |key, value|
            duplicate_data[key] = call(value) if value.is_a?(Enumerable)
          end
        end

        def dup_array_values(duplicate_data)
          duplicate_data.each_with_index do |value, index|
            duplicate_data[index] = call(value) if value.is_a?(Enumerable)
          end
        end
      end
    end
  end
end
