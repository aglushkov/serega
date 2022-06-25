# frozen_string_literal: true

class Serega
  module Plugins
    module Preloads
      class MainPreloadPath
        module ClassMethods
          # @param preloads [Hash] Formatted user provided preloads hash
          def call(preloads)
            return FROZEN_EMPTY_ARRAY if preloads.empty?

            main_path(preloads)
          end

          private

          # Generates path (Array) to the last included resource.
          # We need to know this path to include nested associations.
          #
          #  main_path(a: { b: { c: {} }, d: {} }) # => [:a, :d]
          #
          def main_path(hash, path = [])
            current_level = path.size

            hash.each do |key, data|
              path.pop(path.size - current_level)
              path << key

              main_path(data, path)
            end

            path
          end
        end

        extend ClassMethods
      end
    end
  end
end
