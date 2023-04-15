# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin `:preloads`
    #
    # Allows to define `:preloads` to attributes and then allows to merge preloads
    # from serialized attributes and return single associations hash.
    #
    # Plugin accepts options:
    # - `auto_preload_attributes_with_delegate` - default false
    # - `auto_preload_attributes_with_serializer` - default false
    # - `auto_hide_attributes_with_preload` - default false
    #
    # This options are very handy if you want to forget about finding preloads manually.
    #
    # Preloads can be disabled with `preload: false` attribute option option.
    # Also automatically added preloads can be overwritten with manually specified `preload: :another_value`.
    #
    # Some examples, **please read comments in the code below**
    #
    # @example
    #   class AppSerializer < Serega
    #     plugin :preloads,
    #       auto_preload_attributes_with_delegate: true,
    #       auto_preload_attributes_with_serializer: true,
    #       auto_hide_attributes_with_preload: true
    #   end
    #
    #   class UserSerializer < AppSerializer
    #     # No preloads
    #     attribute :username
    #
    #     # Specify `preload: :user_stats` manually
    #     attribute :followers_count, preload: :user_stats, value: proc { |user| user.user_stats.followers_count }
    #
    #     # Automatically `preloads: :user_stats` as `auto_preload_attributes_with_delegate` option is true
    #     attribute :comments_count, delegate: { to: :user_stats }
    #
    #     # Automatically `preloads: :albums` as `auto_preload_attributes_with_serializer` option is true
    #     attribute :albums, serializer: 'AlbumSerializer'
    #   end
    #
    #   class AlbumSerializer < AppSerializer
    #     attribute :images_count, delegate: { to: :album_stats }
    #   end
    #
    #   # By default preloads are empty, as we specify `auto_hide_attributes_with_preload = true`,
    #   # and attributes with preloads will be not serialized
    #   UserSerializer.new.preloads # => {}
    #   UserSerializer.new.to_h(OpenStruct.new(username: 'foo')) # => {:username=>"foo"}
    #
    #   UserSerializer.new(with: :followers_count).preloads # => {:user_stats=>{}}
    #   UserSerializer.new(with: %i[followers_count comments_count]).preloads # => {:user_stats=>{}}
    #   UserSerializer.new(with: [:followers_count, :comments_count, { albums: :images_count }]).preloads # => {:user_stats=>{}, :albums=>{:album_stats=>{}}}
    #

    module Preloads
      DEFAULT_CONFIG = {
        auto_preload_attributes_with_delegate: false,
        auto_preload_attributes_with_serializer: false,
        auto_hide_attributes_with_preload: false
      }.freeze

      private_constant :DEFAULT_CONFIG

      # @return [Symbol] Plugin name
      def self.plugin_name
        :preloads
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::SeregaAttributeNormalizer.include(AttributeNormalizerInstanceMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaPlanPoint.include(MapPointInstanceMethods)

        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)

        require_relative "./lib/format_user_preloads"
        require_relative "./lib/main_preload_path"
        require_relative "./lib/preloads_constructor"
        require_relative "./validations/check_opt_preload"
        require_relative "./validations/check_opt_preload_path"
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        config.attribute_keys << :preload << :preload_path

        preloads_opts = DEFAULT_CONFIG.merge(opts.slice(*DEFAULT_CONFIG.keys))
        config.opts[:preloads] = {}
        preloads_config = config.preloads
        preloads_config.auto_preload_attributes_with_delegate = preloads_opts[:auto_preload_attributes_with_delegate]
        preloads_config.auto_preload_attributes_with_serializer = preloads_opts[:auto_preload_attributes_with_serializer]
        preloads_config.auto_hide_attributes_with_preload = preloads_opts[:auto_hide_attributes_with_preload]
      end

      #
      # Serega additional/patched instance methods
      #
      # @see Serega
      #
      module InstanceMethods
        # @return [Hash] merged preloads of all serialized attributes
        def preloads
          @preloads ||= PreloadsConstructor.call(plan)
        end
      end

      #
      # Config for `preloads` plugin
      #
      class PreloadsConfig
        # @return [Hash] preloads plugin options
        attr_reader :opts

        #
        # Initializes context_metadata config object
        #
        # @param opts [Hash] options
        #
        # @return [Serega::SeregaPlugins::Metadata::MetadataConfig]
        #
        def initialize(opts)
          @opts = opts
        end

        # @!method auto_preload_attributes_with_delegate
        #   @return [Boolean, nil] option value
        #
        # @!method auto_preload_attributes_with_delegate=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        # @!method auto_preload_attributes_with_serializer
        #   @return [Boolean, nil] option value
        #
        # @!method auto_preload_attributes_with_serializer=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        # @!method auto_hide_attributes_with_preload
        #   @return [Boolean, nil] option value
        #
        # @!method auto_hide_attributes_with_preload=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        %i[
          auto_preload_attributes_with_delegate
          auto_preload_attributes_with_serializer
          auto_hide_attributes_with_preload
        ].each do |method_name|
          define_method(method_name) do
            opts.fetch(method_name)
          end

          define_method("#{method_name}=") do |value|
            raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
            opts[method_name] = value
          end
        end
      end

      #
      # Config class additional/patched instance methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        # @return [Serega::SeregaPlugins::Preloads::PreloadsConfig] `preloads` plugin config
        def preloads
          @preloads ||= PreloadsConfig.new(opts.fetch(:preloads))
        end
      end

      #
      # Serega::SeregaAttribute additional/patched instance methods
      #
      # @see Serega::SeregaAttribute::AttributeInstanceMethods
      #
      module AttributeInstanceMethods
        # @return [Hash, nil] normalized preloads of current attribute
        attr_reader :preloads

        # @return [Array] normalized preloads_path of current attribute
        attr_reader :preloads_path

        private

        def set_normalized_vars(normalizer)
          super
          @preloads = normalizer.preloads
          @preloads_path = normalizer.preloads_path
        end
      end

      #
      # Serega::SeregaAttribute additional/patched instance methods
      #
      # @see Serega::SeregaAttribute::AttributeInstanceMethods
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
          opts = init_opts
          path = Array(opts[:preload_path]).map!(&:to_sym).freeze
          path = MainPreloadPath.call(preloads) if path.empty?
          path
        end

        #
        # Patch for original `prepare_hide` method
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

      #
      # Serega::SeregaPlanPoint additional/patched instance methods
      #
      # @see Serega::SeregaPlanPoint::InstanceMethods
      #
      module MapPointInstanceMethods
        #
        # @return [Hash] preloads for nested attributes
        #
        def preloads
          @preloads ||= PreloadsConstructor.call(nested_points)
        end

        #
        # @return [Array<Symbol>] preloads path for current attribute
        #
        def preloads_path
          attribute.preloads_path
        end
      end

      #
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super
          CheckOptPreload.call(opts)
          CheckOptPreloadPath.call(opts)
        end
      end
    end

    register_plugin(Preloads.plugin_name, Preloads)
  end
end
