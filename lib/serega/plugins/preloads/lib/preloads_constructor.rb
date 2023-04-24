# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Finds preloads for provided attributes plan
      #
      class PreloadsConstructor
        class << self
          #
          # Constructs preloads hash for given attributes plan
          #
          # @param plan [Array<Serega::PlanPoint>] Serialization plan
          #
          # @return [Hash]
          #
          def call(plan)
            return FROZEN_EMPTY_HASH unless plan

            preloads = {}
            append_many(preloads, plan)
            preloads
          end

          private

          def append_many(preloads, plan)
            plan.points.each do |point|
              current_preloads = point.attribute.preloads
              next unless current_preloads

              child_plan = point.child_plan
              current_preloads = SeregaUtils::EnumDeepDup.call(current_preloads) if child_plan
              append_current(preloads, current_preloads)
              next unless child_plan

              child_preloads = dig?(preloads, point.preloads_path)
              append_many(child_preloads, child_plan)
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

          def dig?(hash, path)
            return hash if !path || path.empty?

            path.each do |point|
              hash = hash[point]
            end

            hash
          end
        end
      end
    end
  end
end
