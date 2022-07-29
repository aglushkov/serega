# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Finds relations to preload for provided serializer
      #
      class PreloadsConstructor
        module ClassMethods
          #
          # Constructs preloads hash for given serializer
          #
          # @param serializer [Serega] Instance of Serega serializer
          #
          # @return [Hash]
          #
          def call(map)
            preloads = {}
            append_many(preloads, map)
            preloads
          end

          private

          def append_many(preloads, map)
            map.each do |attribute, nested_map|
              current_preloads = attribute.preloads
              next unless current_preloads

              has_nested = nested_map.any?
              current_preloads = SeregaUtils::EnumDeepDup.call(current_preloads) if has_nested
              append_current(preloads, current_preloads)
              next unless has_nested

              nested_preloads = nested(preloads, attribute.preloads_path)
              append_many(nested_preloads, nested_map)
            end
          end

          def append_current(preloads, current_preloads)
            merge(preloads, current_preloads) unless current_preloads.empty?
          end

          def merge(preloads, current_preloads)
            preloads.merge!(current_preloads) do |_key, value_one, value_two|
              merge(value_one, value_two)
            end
          end

          def nested(preloads, path)
            !path || path.empty? ? preloads : preloads.dig(*path)
          end
        end

        extend ClassMethods
      end
    end
  end
end
