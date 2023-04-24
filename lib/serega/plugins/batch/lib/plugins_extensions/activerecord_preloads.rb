# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Extensions (mini-plugins) that are enabled when :batch plugin used with other plugins
      #
      module PluginsExtensions
        #
        # Extension that is used when :batch plugin used with :active_record_preloads plugin
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
            def keys_values
              data = super

              if point.child_plan
                associations = point.preloads
                return data if associations.empty?

                records = data.values
                records.flatten!(1)

                ActiverecordPreloads::Preloader.preload(records, associations)
              end

              data
            end
          end
        end
      end
    end
  end
end
