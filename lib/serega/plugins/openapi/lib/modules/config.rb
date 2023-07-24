# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module OpenAPI
      #
      # Config class additional/patched instance methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        #
        # Returns openapi plugin config
        #
        # @return [Serega::SeregaPlugins::OpenAPI::OpenAPIConfig] configuration for openapi plugin
        #
        def openapi
          @openapi ||= OpenAPIConfig.new(self.class.serializer_class, opts.fetch(:openapi))
        end
      end
    end
  end
end
