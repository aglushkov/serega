# frozen_string_literal: true

class Serega
  module SeregaValidations
    module Attribute
      #
      # Attribute `:lazy` option validator
      #
      class CheckOptLazy
        class << self
          #
          # Checks attribute :lazy option
          #
          # @param opts [Hash] Attribute options
          #
          # @raise [SeregaError] Attribute validation error
          #
          # @return [void]
          #
          def call(serializer_class, opts, block)
            return unless opts.key?(:lazy)
            lazy = opts[:lazy]

            return if lazy == true
            return if lazy.respond_to?(:call)

            check_opt_lazy(opts)

            check_usage_with_other_params(opts, block)
          end

          private

          def check_opt_lazy(opts)
            Utils::CheckOptIsHash.call(opts, :lazy)

            lazy_opts = opts[:lazy]
            check_opt_lazy_use(lazy_opts)
            check_opt_lazy_id(lazy_opts)
            check_opt_lazy_extra_opts(lazy_opts)
          end

          def check_opt_lazy_use(lazy_opts)
            return unless lazy_opts.key?(:use)

            lazy_loader_name = lazy_opts[:use]
            return if lazy_loader_name.respond_to?(:call)

            check_loader_exists?(lazy_loader_name)
          end

          def check_opt_lazy_id(lazy_opts)
            return unless lazy_opts.key?(:id)

            id_method_name = lazy_opts[:id]
            return if id_method_name.is_a?(Symbol) || id_method_name.is_a?(String)

            raise SeregaError, "Invalid lazy option `:id` value, it can be a Symbol or a String"
          end

          def check_loader_exists?(value)
            raise SeregaError, "Lazy loader name must be present" unless value

            values = Array(value)
            values.each do |lazy_loader_name|
              next if serializer_class.lazy_loaders.key?(lazy_loader_name.to_sym)

              raise SeregaError, "Lazy loader with name `#{lazy_loader_name.inspect}` is not defined"
            end
          end

          def check_opt_lazy_extra_opts(lazy_opts)
            Utils::CheckAllowedKeys.call(lazy_opts, %i[use id], :lazy)
          end


          def check_usage_with_other_params(opts, block)
            lazy = opts[:lazy]
            use_id = lazy.key?(:id)
            use_multiple = Array(lazy[:use]).size > 1
            value_added = opts.key?(:value) || block

            if use_multiple && use_id
              raise SeregaError, "Option `lazy.id` should not be used with multiple loaders provided in `lazy.use`"
            end

            if use_multiple && !value_added
              raise SeregaError, "Attribute :value option or block should be provided when selecting multiple lazy loaders"
            end

            if use_id && (value_added)
              raise SeregaError, "Option `lazy.id` should not be used when :value or block provided directly"
            end

            raise SeregaError, "Option :lazy can not be used together with option :method" if opts.key?(:method)
            raise SeregaError, "Option :lazy can not be used together with option :const" if opts.key?(:const)
            raise SeregaError, "Option :lazy can not be used together with option :delegate" if opts.key?(:delegate)
          end
        end
      end
    end
  end
end
