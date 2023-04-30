# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Config class additional/patched instance methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        #
        # Returns all batch loaders registered for current serializer
        #
        # @return [Serega::SeregaPlugins::Batch::BatchConfig] configuration for batch loaded attributes
        #
        def batch
          @batch ||= BatchConfig.new(opts.fetch(:batch))
        end
      end
    end
  end
end
