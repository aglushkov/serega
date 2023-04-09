# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Class that constructs main preloads path.
      #
      # When we have nested preloads we will use this path to dig to `main` element and
      # assign nested preloads to it.
      #
      # By default its a path to latest provided preload
      #
      # @example
      #  MainPreloadPath.(a: { b: { c: {} }, d: {} }) # => [:a, :d]
      #
      class MainPreloadPath
        class << self
          # Finds default preload path
          #
          # @param preloads [Hash] Formatted user provided preloads hash
          #
          # @return [Array<Symbol>] Preloads path to `main` element
          def call(preloads)
            return FROZEN_EMPTY_ARRAY if preloads.empty?

            main_path(preloads).freeze
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
      end
    end
  end
end
