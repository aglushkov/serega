# frozen_string_literal: true

class Serega
  module Validations
    class CheckSerializeParams
      module ClassMethods
        def call(opts)
          check_opts(opts)
        end

        private

        def check_opts(opts)
          Utils::CheckAllowedKeys.call(opts, allowed_opts_keys)

          Utils::CheckOptIsHash.call(opts, :context)
          Utils::CheckOptIsBool.call(opts, :many)
        end

        def allowed_opts_keys
          serializer_class.config[:serialize_keys]
        end
      end

      extend ClassMethods
      extend Serega::Helpers::SerializerClassHelper
    end
  end
end
