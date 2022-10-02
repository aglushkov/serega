# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Root
      # @return [Symbol] Default response root key
      ROOT_DEFAULT = :data

      def self.plugin_name
        :root
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
        serializer_class::SeregaSerializer.include(SerializerInstanceMethods)
      end

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
        # @param root_one [String, Symbol] Specifies root when serializing one object
        # @param root_many [String, Symbol] Specifies root when serializing multiple objects
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

      module SerializerInstanceMethods
        def serialize(_object)
          result = super
          root = build_root(result, opts)
          result = {root => result} if root
          result
        end

        private

        def build_root(result, opts)
          return opts[:root] if opts.key?(:root)

          root = self.class.serializer_class.config.root
          result.is_a?(Array) ? root.many : root.one
        end
      end
    end

    register_plugin(Root.plugin_name, Root)
  end
end
