# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Extensions (mini-plugins) that are enabled when :batch plugin used with other plugins
      #
      module PluginsExtensions
        #
        # Extension that is used when :if plugin is loaded
        #
        module If
          #
          # SeregaObjectSerializer additional/patched class methods
          #
          # @see Serega::SeregaObjectSerializer
          #
          module ObjectSerializerInstanceMethods123
            private

            # Removes key added by `batch` plugin at the start of serialization to preserve attributes ordering
            def attach_final_value(value, point, container)
              container.delete(point.name) if super == SeregaPlugins::If::KEY_SKIPPED
            end
          end
        end
      end
    end
  end
end
