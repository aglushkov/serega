# frozen_string_literal: true

class Serega
  module SeregaValidations
    class CheckInitiateParams
      module ClassMethods
        def call(opts)
          check_opts(opts)
        end

        private

        def check_opts(opts)
          SeregaUtils::CheckAllowedKeys.call(opts, allowed_opts_keys)
        end

        def allowed_opts_keys
          serializer_class.config[:initiate_keys]
        end
      end

      extend ClassMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
