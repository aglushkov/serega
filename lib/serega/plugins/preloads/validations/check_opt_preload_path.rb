# frozen_string_literal: true

class Serega
  module Plugins
    module Preloads
      class CheckOptPreloadPath
        class << self
          def call(opts)
            return unless opts.key?(:preload_path)

            value = opts[:preload_path]
            raise Error, "Invalid option :preload_path => #{value.inspect}. Can be provided only when :preload option provided" unless opts[:preload]
            raise Error, "Invalid option :preload_path => #{value.inspect}. Can be provided only when :serializer option provided" unless opts[:serializer]

            path = Array(value).map!(&:to_sym)
            preloads = FormatUserPreloads.call(opts[:preload])
            allowed_paths = paths(preloads)
            raise Error, "Invalid option :preload_path => #{value.inspect}. Can be one of #{allowed_paths.inspect[1..-2]}" unless allowed_paths.include?(path)
          end

          private

          def paths(preloads, path = [], result = [])
            preloads.each do |key, nested_preloads|
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
