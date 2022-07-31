# frozen_string_literal: true

class Serega
  module SeregaValidations
    class CheckAttributeParams
      module InstanceMethods
        attr_reader :name, :opts, :block

        def initialize(name, opts, block)
          @name = name
          @opts = opts
          @block = block
        end

        def validate
          check_name
          check_opts
          check_block
        end

        private

        def check_name
          Attribute::CheckName.call(name)
        end

        def check_opts
          SeregaUtils::CheckAllowedKeys.call(opts, allowed_opts_keys)

          Attribute::CheckOptConst.call(opts, block)
          Attribute::CheckOptHide.call(opts)
          Attribute::CheckOptKey.call(opts, block)
          Attribute::CheckOptMany.call(opts)
          Attribute::CheckOptSerializer.call(opts)
          Attribute::CheckOptValue.call(opts, block)
        end

        def check_block
          Attribute::CheckBlock.call(block)
        end

        def allowed_opts_keys
          self.class.serializer_class.config[:attribute_keys]
        end
      end

      include InstanceMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
