# frozen_string_literal: true

class Serega
  #
  # Validations
  #
  module SeregaValidations
    #
    # Validations for attribute params
    #
    class CheckAttributeParams
      #
      # Validations for attribute params instance methods
      #
      module InstanceMethods
        # @return [Symbol] validated attribute name
        attr_reader :name

        # @return [Hash] validated attribute options
        attr_reader :opts

        # @return [nil, Proc] validated attribute block
        attr_reader :block

        #
        # Initializes attribute params validator
        #
        # @param name [Symbol] attribute name
        # @param opts [Hash] attribute options
        # @param block [nil, Proc] block provided to attribute
        #
        # @return [void]
        #
        def initialize(name, opts, block)
          @name = name
          @opts = opts
          @block = block
        end

        #
        # Validates attribute params
        #
        def validate
          check_name
          check_opts
          check_block
        end

        private

        def check_name
          Attribute::CheckName.call(name)
        end

        # Patched in:
        # - plugin :batch (checks :batch option)
        # - plugin :context_metadata (checks context metadata option which is :meta by default)
        # - plugin :if (checks :if, :if_value, :unless, :unless_value options)
        # - plugin :preloads (checks :preload option)
        def check_opts
          Utils::CheckAllowedKeys.call(opts, allowed_opts_keys)

          Attribute::CheckOptConst.call(opts, block)
          Attribute::CheckOptDelegate.call(opts, block)
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
          self.class.serializer_class.config.attribute_keys
        end
      end

      include InstanceMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
