# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      # Transforms user provided preloads to hash
      class FormatUserPreloads
        METHODS = {
          Array => :array_to_hash,
          FalseClass => :nil_to_hash,
          Hash => :hash_to_hash,
          NilClass => :nil_to_hash,
          String => :string_to_hash,
          Symbol => :symbol_to_hash
        }.freeze

        module ClassMethods
          def call(value)
            send(METHODS.fetch(value.class), value)
          end

          private

          def array_to_hash(values)
            values.each_with_object({}) do |value, obj|
              obj.merge!(call(value))
            end
          end

          def hash_to_hash(values)
            values.each_with_object({}) do |(key, value), obj|
              obj[key.to_sym] = call(value)
            end
          end

          def nil_to_hash(_value)
            {}
          end

          def string_to_hash(value)
            symbol_to_hash(value.to_sym)
          end

          def symbol_to_hash(value)
            {value => {}}
          end
        end

        extend ClassMethods
      end
    end
  end
end
