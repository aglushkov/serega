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
        require_relative "./lib/format_user_preloads"
        require_relative "./lib/modules/attribute"
        require_relative "./lib/modules/attribute_normalizer"
        require_relative "./lib/modules/check_attribute_params"
        require_relative "./lib/modules/config"
        require_relative "./lib/modules/plan_point"
        require_relative "./lib/preload_paths"
        require_relative "./lib/preloads_config"
        require_relative "./lib/preloads_constructor"
        require_relative "./validations/check_opt_preload"
        require_relative "./validations/check_opt_preload_path"

        serializer_class.include(InstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::SeregaAttributeNormalizer.include(AttributeNormalizerInstanceMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaPlanPoint.include(PlanPointInstanceMethods)

        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
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
    end

    register_plugin(Preloads.plugin_name, Preloads)
  end
end
