# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # SeregaObjectSerializer additional/patched class methods
      #
      # @see Serega::SeregaObjectSerializer
      #
      module SeregaObjectSerializerInstanceMethods
        private

        def attach_value(object, point, container)
          batch = point.batch
          return super unless batch

          remember_key_for_batch_loading(batch, object, point, container)
        end

        def remember_key_for_batch_loading(batch, object, point, container)
          id = batch[:id_method].call(object, context)
          batch_loader(point).remember(id, container)
          container[point.name] = nil # Reserve attribute place in resulted hash. We will set correct value later
        end

        def batch_loader(point)
          batch_loaders = opts[:batch_loaders]
          raise_batch_plugin_for_serializer_not_defined(point) unless batch_loaders
          batch_loaders.get(point, self)
        end

        def raise_batch_plugin_for_serializer_not_defined(point)
          root_plan = point.plan
          root_plan = plan.parent_plan_point.plan while root_plan.parent_plan_point
          current_serializer = root_plan.serializer_class
          nested_serializer = self.class.serializer_class

          raise SeregaError,
            "Plugin :batch must be added to current serializer (#{current_serializer})" \
            " to load attributes with :batch option in nested serializer (#{nested_serializer})"
        end
      end
    end
  end
end
