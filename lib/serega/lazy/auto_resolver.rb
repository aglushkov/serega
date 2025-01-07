# frozen_string_literal: true

class Serega
  module SeregaLazy
    #
    # Automatically generated resolver for lazy_loader
    #
    class AutoResolver
      def initialize(loader_name, id_method)
        @loader_name = loader_name
        @id_method = id_method
      end

      # Finds object attribute value from hash of lazy_loaded values for all
      # serialized objects
      def call(obj, lazy:)
        lazy.fetch(@loader_name)[obj.public_send(@id_method)]
      end
    end
  end
end
