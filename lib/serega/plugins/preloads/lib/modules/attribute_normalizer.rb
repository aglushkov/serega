# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Serega::SeregaAttributeNormalizer additional/patched instance methods
      #
      # @see SeregaAttributeNormalizer::AttributeNormalizerInstanceMethods
      #
      module AttributeNormalizerInstanceMethods
        # @return [Hash,nil] normalized attribute preloads
        def preloads
          return @preloads if instance_variable_defined?(:@preloads)

          @preloads = prepare_preloads
        end

        # @return [Array, nil] normalized attribute preloads path
        def preloads_path
          return @preloads_path if instance_variable_defined?(:@preloads_path)

          @preloads_path = prepare_preloads_path
        end

        private

        #
        # Patched in:
        # - plugin :batch (extension :preloads - skips auto preloads when batch option provided)
        #
        def prepare_preloads
          opts = init_opts
          preloads_provided = opts.key?(:preload)
          preloads =
            if preloads_provided
              opts[:preload]
            elsif opts.key?(:serializer) && self.class.serializer_class.config.preloads.auto_preload_attributes_with_serializer
              key
            elsif opts.key?(:delegate) && self.class.serializer_class.config.preloads.auto_preload_attributes_with_delegate
              opts[:delegate].fetch(:to)
            end

          # Nil and empty hash differs as we can preload nested results to
          # empty hash, but we will skip nested preloading if nil or false provided
          return if preloads_provided && !preloads

          FormatUserPreloads.call(preloads)
        end

        def prepare_preloads_path
          path = init_opts.fetch(:preload_path) { default_preload_path(preloads) }

          if path && path[0].is_a?(Array)
            prepare_many_preload_paths(path)
          else
            prepare_one_preload_path(path)
          end
        end

        def prepare_one_preload_path(path)
          return unless path

          case path
          when Array
            path.map(&:to_sym).freeze
          else
            [path.to_sym].freeze
          end
        end

        def prepare_many_preload_paths(paths)
          paths.map { |path| prepare_one_preload_path(path) }.freeze
        end

        def default_preload_path(preloads)
          return FROZEN_EMPTY_ARRAY if !preloads || preloads.empty?

          [preloads.keys.first]
        end

        #
        # Patch for original `prepare_hide` method
        # @see
        #
        # Marks attribute hidden if auto_hide_attribute_with_preloads option was set and attribute has preloads
        #
        def prepare_hide
          res = super
          return res unless res.nil?

          if preloads && !preloads.empty?
            self.class.serializer_class.config.preloads.auto_hide_attributes_with_preload || nil
          end
        end
      end
    end
  end
end
