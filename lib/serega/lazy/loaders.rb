# frozen_string_literal: true

class Serega
  #
  # Lazy feature main module
  #
  module SeregaLazy
    class SerializerObjectContainer
      attr_reader :serializer
      attr_reader :object
      attr_reader :container

      def initialize(serializer, object, container)
        @serializer = serializer
        @object = object
        @container = container
      end
    end

    #
    # Storage for data that must be lazily loaded
    #
    class PointLazyLoader
      def initialize(point)
        @point = point
        @objects = []
        @serializer_object_containers = []
      end

      def append(serializer, object, container)
        objects << object
        serializer_object_containers << SerializerObjectContainer.new(serializer, object, container)
      end

      def load_all(context)
        lazy = {}
        serializer_class = point.class.serializer_class

        point.lazy_loaders.each do |lazy_loader_name|
          lazy[lazy_loader_name] ||= serializer_class.lazy_loaders[lazy_loader_name].load(objects, context)
        end

        serializer_object_containers.each do |data|
          data.serializer.__send__(:attach_value, data.object, point, data.container, lazy: lazy)
        end
      end

      private

      attr_reader :point
      attr_reader :objects
      attr_reader :serializer_object_containers
    end

    #
    #  Lazy loaders
    #
    class Loaders
      #
      # Initializes new lazy loaders
      #
      # @param name [Symbol, String] Name of attribute
      # @param block [#call] LazyLoader block
      #
      def initialize
        @point_lazy_loaders = []
        @point_index = {}.compare_by_identity
      end

      # Remembers object and its container to load later
      def remember(serializer, point, object, container)
        point_lazy_loader = point_index[point]

        unless point_lazy_loader
          point_lazy_loader = PointLazyLoader.new(point)
          point_lazy_loaders << point_lazy_loader
          point_index[point] = point_lazy_loader
        end

        point_lazy_loader.append(serializer, object, container)
      end

      #
      # Loads all registered batches and removes them from registered list
      #
      def load_all(context)
        point_lazy_loaders.each do |point_lazy_loader|
          point_lazy_loader.load_all(context)
        end
      end

      private

      # keeps all point_lazy_loaders list
      attr_reader :point_lazy_loaders

      # keeps tracking of already added serializers
      attr_reader :point_index
    end
  end
end
