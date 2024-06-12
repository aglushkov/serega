# frozen_string_literal: true

class Serega
  module SeregaUtils
    #
    # Utility to transform almost anything to Hash with strigified frozen keys
    #
    class ToStringifiedHash
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
          when String, Symbol then string_to_hash(value)
          else raise SeregaError, "Can't convert #{value.class} class object to hash"
          end
        end

        private

        def array_to_hash(values)
          return FROZEN_EMPTY_HASH if values.empty?

          res = {}
          values.each do |value|
            case value
            when String, Symbol
              key = to_key(value)
              res[key] = FROZEN_EMPTY_HASH
            else
              res.merge!(call(value))
            end
          end
          res
        end

        def hash_to_hash(values)
          return FROZEN_EMPTY_HASH if values.empty?

          res = {}
          values.each do |key, value|
            key = to_key(key)
            value = call(value)
            res[key] = value
          end
          res
        end

        def nil_to_hash(_value)
          FROZEN_EMPTY_HASH
        end

        def string_to_hash(value)
          key = to_key(value)
          {key => FROZEN_EMPTY_HASH}
        end

        def to_key(value)
          SymbolName.call(value)
        end
      end
    end
  end
end
