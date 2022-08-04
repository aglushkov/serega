# frozen_string_literal: true

class Serega
  module SeregaValidations
    class CheckSerializeParams
      module InstanceMethods
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def validate
          check_opts
        end

        private

        def check_opts
          Utils::CheckAllowedKeys.call(opts, serializer_class.config[:serialize_keys])

          Utils::CheckOptIsHash.call(opts, :context)
          Utils::CheckOptIsBool.call(opts, :many)
        end

        def serializer_class
          self.class.serializer_class
        end
      end

      include InstanceMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
