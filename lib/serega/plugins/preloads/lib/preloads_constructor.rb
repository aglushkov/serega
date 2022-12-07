# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Finds preloads for provided attributes map
      #
      class PreloadsConstructor
        class << self
          #
          # Constructs preloads hash for given attributes map
          #
          # @param map [Array<Serega::MapPoint>] Serialization map
          #
          # @return [Hash]
          #
          def call(map)
            return FROZEN_EMPTY_HASH unless map

            preloads = {}
            append_many(preloads, map)
            preloads
          end

          private

          def append_many(preloads, map)
            map.each do |point|
              current_preloads = point.attribute.preloads
              next unless current_preloads

              has_nested = point.has_nested_points?
              current_preloads = SeregaUtils::EnumDeepDup.call(current_preloads) if has_nested
              append_current(preloads, current_preloads)
              next unless has_nested

              nested_preloads = nested(preloads, point.preloads_path)
              append_many(nested_preloads, point.nested_points)
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
            (!path || path.empty?) ? preloads : preloads.dig(*path)
          end
        end
      end
    end
  end
end
