# frozen_string_literal: true

class Serega
  module SeregaUtils
    #
    # Utility to transform almost anything to Hash
    #
    class ToHash
      class << self
        #
        # Constructs deep hashes from provided data
        #
        # @param value [Array, Hash, String, Symbol, NilClass, FalseClass] Value to transform
        #
        # @example
        #   Serega::SeregaUtils::ToHash.(nil) # => {}
        #   Serega::SeregaUtils::ToHash.(false) # => {}
        #   Serega::SeregaUtils::ToHash.(:foo) # => {:foo=>{}}
        #   Serega::SeregaUtils::ToHash.("foo") # => {:foo=>{}}
        #   Serega::SeregaUtils::ToHash.(%w[foo bar]) # => {:foo=>{}, :bar=>{}}
        #   Serega::SeregaUtils::ToHash.({ foo: nil, bar: false }) # => {:foo=>{}, :bar=>{}}
        #   Serega::SeregaUtils::ToHash.({ foo: :bar }) # => {:foo=>{:bar=>{}}}
        #   Serega::SeregaUtils::ToHash.({ foo: [:bar] }) # => {:foo=>{:bar=>{}}}
        #
        # @return [Hash] Transformed data
        #
        def call(value)
          case value
          when Array then array_to_hash(value)
          when Hash then hash_to_hash(value)
          when NilClass, FalseClass then nil_to_hash(value)
          when String then string_to_hash(value)
          when Symbol then symbol_to_hash(value)
          else raise SeregaError, "Cant convert #{value.class} class object to hash"
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
    end
  end
end
