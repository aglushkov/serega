# frozen_string_literal: true

class Serega
  module SeregaUtils
    class ToHash
      module ClassMethods
        def call(value)
          case value
          when Array then array_to_hash(value)
          when Hash then hash_to_hash(value)
          when NilClass, FalseClass then nil_to_hash(value)
          when String then string_to_hash(value)
          when Symbol then symbol_to_hash(value)
          else raise Error, "Cant convert #{value.class} class object to hash"
          end
        end

        private

        def array_to_hash(values)
          return Serega::FROZEN_EMPTY_HASH if values.empty?

          values.each_with_object({}) do |value, obj|
            obj.merge!(call(value))
          end
        end

        def hash_to_hash(values)
          return Serega::FROZEN_EMPTY_HASH if values.empty?

          values.each_with_object({}) do |(key, value), obj|
            obj[key.to_sym] = call(value)
          end
        end

        def nil_to_hash(_value)
          Serega::FROZEN_EMPTY_HASH
        end

        def string_to_hash(value)
          symbol_to_hash(value.to_sym)
        end

        def symbol_to_hash(value)
          {value => Serega::FROZEN_EMPTY_HASH}
        end
      end

      extend ClassMethods
    end
  end
end
