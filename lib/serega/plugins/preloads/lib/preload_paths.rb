# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Utility that helps to transform preloads to array of paths
      #
      # Example:
      #
      #   call({ a: { b: { c: {}, d: {} } }, e: {} })
      #
      #   => [
      #        [:a],
      #        [:a, :b],
      #        [:a, :b, :c],
      #        [:a, :b, :d],
      #        [:e]
      #      ]
      class PreloadPaths
        class << self
          #
          # Transforms user provided preloads to array of paths
          #
          # @param preloads [Array,Hash,String,Symbol,nil,false] association(s) to preload
          #
          # @return [Hash] preloads transformed to hash
          #
          def call(preloads)
            formatted_preloads = FormatUserPreloads.call(preloads)
            return FROZEN_EMPTY_ARRAY if formatted_preloads.empty?

            paths(formatted_preloads, [], [])
          end

          private

          def paths(formatted_preloads, path, result)
            formatted_preloads.each do |key, nested_preloads|
              path << key
              result << path.dup

              paths(nested_preloads, path, result)
              path.pop
            end

            result
          end
        end
      end
    end
  end
end
