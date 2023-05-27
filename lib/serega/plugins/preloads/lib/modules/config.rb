# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Config class additional/patched instance methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        # @return [Serega::SeregaPlugins::Preloads::PreloadsConfig] `preloads` plugin config
        def preloads
          @preloads ||= PreloadsConfig.new(opts.fetch(:preloads))
        end
      end
    end
  end
end
