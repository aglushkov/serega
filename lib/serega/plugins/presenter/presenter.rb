# frozen_string_literal: true

require "delegate"
require "forwardable"

class Serega
  module SeregaPlugins
    #
    # Plugin Presenter adds possibility to use declare Presenter for your objects inside serializer
    #
    #   class User < Serega
    #     plugin :presenter
    #
    #     attribute :name
    #
    #     class Presenter
    #       def name
    #         [first_name, last_name].compact_blank.join(' ')
    #       end
    #     end
    #   end
    module Presenter
      # @return [Symbol] plugin name
      def self.plugin_name
        :presenter
      end

      #
      # Loads plugin
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class.extend(ClassMethods)
        serializer_class::SeregaSerializer.include(SeregaSerializerInstanceMethods)
      end

      #
      # Adds Presenter to current serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **_opts)
        presenter_class = Class.new(Presenter)
        presenter_class.serializer_class = serializer_class
        serializer_class.const_set(:Presenter, presenter_class)
      end

      # Presenter class
      class Presenter < SimpleDelegator
        # Presenter instance methods
        module InstanceMethods
          #
          # Delegates all missing methods to serialized object.
          #
          # Creates delegator method after first #method_missing hit to improve
          # performance of following serializations.
          #
          def method_missing(name, *_args, &_block) # rubocop:disable Style/MissingRespondToMissing (base SimpleDelegator class has this method)
            super.tap do
              self.class.def_delegator :__getobj__, name
            end
          end
        end

        extend SeregaHelpers::SerializerClassHelper
        extend Forwardable
        include InstanceMethods
      end

      # Overrides class methods of included class
      module ClassMethods
        private def inherited(subclass)
          super

          presenter_class = Class.new(self::Presenter)
          presenter_class.serializer_class = subclass
          subclass.const_set(:Presenter, presenter_class)
        end

        # Overrides {Serega::ClassMethods#attribute} method, additionally adds method
        # to Presenter to not hit {Serega::SeregaPlugins::Presenter::Presenter#method_missing}
        # @see Serega::ClassMethods#attribute
        def attribute(_name, **_opts, &_block)
          super.tap do |attribute|
            self::Presenter.def_delegator(:__getobj__, attribute.key) unless attribute.block
          end
        end
      end

      # Includes methods to override SeregaSerializer class
      module SeregaSerializerInstanceMethods
        #
        # Replaces serialized object with Presenter.new(object)
        #
        def serialize(object)
          presenter_class = points.first.class.serializer_class::Presenter
          object = presenter_class.new(object)
          super
        end
      end
    end

    register_plugin(Presenter.plugin_name, Presenter)
  end
end
