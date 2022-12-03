# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Root
      # @return [Symbol] Default response root key
      ROOT_DEFAULT = :data

      # @return [Symbol] Plugin name
      def self.plugin_name
        :root
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
        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
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
        default = opts[:root] || ROOT_DEFAULT
        one = (opts[:root_one] || default).to_sym
        many = (opts[:root_many] || default).to_sym
        config.opts[:root] = {one: one, many: many}
        config.serialize_keys << :root
      end

      module ClassMethods
        #
        # Configures response root key
        #
        # @param root [String, Symbol] Specifies common root when serializing one or multiple objects
        # @param one [String, Symbol] Specifies root when serializing one object
        # @param many [String, Symbol] Specifies root when serializing multiple objects
        #
        # @return [Hash] Configured root names
        #
        def root(root = nil, one: nil, many: nil)
          one ||= root
          many ||= root

          one = one.to_sym if one
          many = many.to_sym if many

          config.root = {one: one, many: many}
        end
      end

      class RootConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def one
          opts.fetch(:one)
        end

        def many
          opts.fetch(:many)
        end

        def one=(value)
          opts[:one] = value
        end

        def many=(value)
          opts[:many] = value
        end
      end

      module ConfigInstanceMethods
        def root
          @root ||= RootConfig.new(opts.fetch(:root))
        end

        def root=(value)
          root.one = value.fetch(:one)
          root.many = value.fetch(:many)
        end
      end

      module InstanceMethods
        private

        def serialize(_object, opts)
          result = super
          root = build_root(result, opts)
          result = {root => result} if root
          result
        end

        def build_root(result, opts)
          return opts[:root] if opts.key?(:root)

          root = self.class.config.root
          result.is_a?(Array) ? root.many : root.one
        end
      end
    end

    register_plugin(Root.plugin_name, Root)
  end
end
