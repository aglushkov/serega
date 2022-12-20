# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Extensions (mini-plugins) that are enabled when :batch plugin used with other plugins
      #
      module PluginsExtensions
        #
        # Extension that is used when :preloads plugin is loaded
        #
        module Preloads
          #
          # Attribute additional/patched instance methods
          #
          # @see Serega::SeregaPlugins::Preloads::AttributeInstanceMethods
          #
          module AttributeInstanceMethods
            private

            # Do not add any preloads automatically when batch option provided
            def get_preloads
              return if batch && !opts.key?(:preload)
              super
            end
          end
        end
      end
    end
  end
end
