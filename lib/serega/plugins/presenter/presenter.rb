# frozen_string_literal: true

require "delegate"
require "forwardable"

class Serega
  module Plugins
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
        serializer_class::ConvertItem.extend(ConvertItemClassMethods)
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

        extend Helpers::SerializerClassHelper
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
        # to Presenter to not hit {Serega::Plugins::Presenter::Presenter#method_missing}
        # @see Serega::ClassMethods#attribute
        def attribute(_name, **_opts, &_block)
          super.tap do |attribute|
            self::Presenter.def_delegator(:__getobj__, attribute.key) unless attribute.block
          end
        end
      end

      # Includes methods to override ConvertItem class
      module ConvertItemClassMethods
        #
        # Replaces serialized object with Presenter.new(object)
        #
        def call(object, *)
          object = serializer_class::Presenter.new(object)
          super
        end
      end
    end

    register_plugin(Presenter.plugin_name, Presenter)
  end
end
