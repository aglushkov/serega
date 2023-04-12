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
          # @see Serega::SeregaPlugins::Preloads::AttributeNormalizerInstanceMethods
          #
          module AttributeNormalizerInstanceMethods
            private

            # Do not add any preloads automatically when batch option provided
            def prepare_preloads
              opts = init_opts
              return if opts.key?(:batch) && !opts.key?(:preload)

              super
            end
          end
        end
      end
    end
  end
end
