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
          # @param value [Array,Hash,String,Symbol,nil,false] preloads
          #
          # @return [Hash] preloads transformed to hash
          #
          def call(preloads, path = [], result = [])
            preloads = FormatUserPreloads.call(preloads)

            preloads.each do |key, nested_preloads|
              path << key
              result << path.dup

              call(nested_preloads, path, result)
              path.pop
            end

            result
          end
        end
      end
    end
  end
end
