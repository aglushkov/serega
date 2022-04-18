# frozen_string_literal: true

class Serega
  module Plugins
    module Preloads
      #
      # Finds relations to preload for provided serializer
      #
      class Preloads
        # Contains Preloads class methods
        module ClassMethods
          #
          # Constructs preloads hash for given serializer
          #
          # @param serializer [Serega] Instance of Serega serializer
          #
          # @return [Hash]
          #
          def call(serializer)
            result = {}
            append_many(result, serializer.class)
            result
          end

          private

          def append_many(result, serializer_class, keys)
            keys.each do |key, inner_keys|
              attribute = serializer_class.attributes.fetch(key)
              preloads = attribute.preloads
              next unless preloads

              append_one(result, serializer_class, preloads)
              next if inner_keys.empty?

              path = attribute.preloads_path
              nested_result = nested(result, path)
              nested_serializer = attribute.serializer

              append_many(nested_result, nested_serializer, inner_keys)
            end
          end

          def append_one(result, serializer_class, preloads)
            return if preloads.empty?

            preloads = Utils::EnumDeepDup.call(preloads)
            merge(result, preloads)
          end

          def merge(result, preloads)
            result.merge!(preloads) do |_key, value_one, value_two|
              merge(value_one, value_two)
            end
          end

          def nested(result, path)
            !path || path.empty? ? result : result.dig(*path)
          end
        end

        extend ClassMethods
      end
    end
  end
end
