# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Serega::SeregaPlanPoint additional/patched instance methods
      #
      # @see Serega::SeregaPlanPoint::InstanceMethods
      #
      module PlanPointInstanceMethods
        #
        # @return [Hash] preloads for nested attributes
        #
        attr_reader :preloads

        #
        # @return [Array<Symbol>] preloads path for current attribute
        #
        attr_reader :preloads_path

        private

        def set_normalized_vars
          super

          @preloads = prepare_preloads
          @preloads_path = prepare_preloads_path
        end

        def prepare_preloads
          PreloadsConstructor.call(child_plan)
        end

        def prepare_preloads_path
          attribute.preloads_path
        end
      end
    end
  end
end
