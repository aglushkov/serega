# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      module PluginsExtensions
        module ActiveRecordPreloads
          module BatchLoaderInstanceMethods
            def keys_values(*)
              data = super

              if point.has_nested_points?
                associations = point.preloads
                return data if associations.empty?

                ActiverecordPreloads::Preloader.preload(data.values.flatten(1), associations)
              end

              data
            end
          end
        end

        module Formatters
          module BatchLoaderInstanceMethods
            # Format values after they are prepared
            def keys_values(*)
              data = super

              formatter = point.attribute.formatter_resolved
              data.transform_values! { |value| formatter.call(value) } if formatter

              data
            end
          end
        end
      end
    end
  end
end
