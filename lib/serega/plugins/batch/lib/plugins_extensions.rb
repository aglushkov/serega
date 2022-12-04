# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      # Extensions (mini-plugins) that are enabled when Batch plugin used with other plugins
      module PluginsExtensions
        #
        # Extension that is used when batch plugin used with :active_record_preloads plugin
        #
        module ActiveRecordPreloads
          #
          # BatchLoader additional/patched instance methods
          #
          # @see Serega::SeregaPlugins::Batch::SeregaBatchLoader
          #
          module BatchLoaderInstanceMethods
            private

            # Preloads required associations to batch-loaded records
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

        #
        # Extension that is used when batch plugin used with :formatters plugin
        #
        module Formatters
          #
          # BatchLoader additional/patched instance methods
          #
          # @see Serega::SeregaPlugins::Batch::SeregaBatchLoader
          #
          module BatchLoaderInstanceMethods
            private

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
