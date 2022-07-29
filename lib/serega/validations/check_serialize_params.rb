# frozen_string_literal: true

class Serega
  module SeregaValidations
    class CheckSerializeParams
      module ClassMethods
        def call(opts)
          check_opts(opts)
        end

        private

        def check_opts(opts)
          SeregaUtils::CheckAllowedKeys.call(opts, allowed_opts_keys)

          SeregaUtils::CheckOptIsHash.call(opts, :context)
          SeregaUtils::CheckOptIsBool.call(opts, :many)
        end

        def allowed_opts_keys
          serializer_class.config[:serialize_keys]
        end
      end

      extend ClassMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
