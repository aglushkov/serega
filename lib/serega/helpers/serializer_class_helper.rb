# frozen_string_literal: true

class Serega
  module SeregaHelpers
    # Stores link to current serializer class
    module SerializerClassHelper
      # @return [Class<Serega>] Serializer class that current class is namespaced under.
      attr_accessor :serializer_class
    end
  end
end
