# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Extensions (mini-plugins) that are enabled when :batch plugin used with other plugins
      #
      module PluginsExtensions
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

              formatter = point.attribute.formatter
              data.transform_values! { |value| formatter.call(value) } if formatter

              data
            end
          end
        end
      end
    end
  end
end
