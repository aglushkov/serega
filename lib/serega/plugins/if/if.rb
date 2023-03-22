# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin adds `:if`, `:unless`, `:if_value`, `:unless_value` options to
    # attributes so we can remove attributes from response in various ways.
    #
    # Use `:if` and `:unless` when you want to hide attributes before finding attribute value,
    # and use `:if_value` and `:unless_value` to hide attributes after we find final value.
    #
    # Options `:if` and `:unless` accept currently serialized object and context as parameters.
    # Options `:if_value` and `:unless_value` accept already found serialized value and context as parameters.
    #
    # Options `:if_value` and `:unless_value` cannot be used with :serializer option, as
    # serialized objects have no "serialized value". Use `:if` and `:unless` in this case.
    #
    # See also a `:hide` option that is available without any plugins to hide
    # attribute without conditions. Look at README.md#selecting-fields for `:hide` usage examples.
    #
    # Examples:
    #  class UserSerializer < Serega
    #    attribute :email, if: :active? # if user.active?
    #    attribute :email, if: proc {|user| user.active?} # same
    #    attribute :email, if: proc {|user, ctx| user == ctx[:current_user]} # using context
    #    attribute :email, if: CustomPolicy.method(:view_email?) # You can provide own callable object
    #
    #    attribute :email, unless: :hidden? # unless user.hidden?
    #    attribute :email, unless: proc {|user| user.hidden?} # same
    #    attribute :email, unless: proc {|user, context| context[:show_emails]} # using context
    #    attribute :email, unless: CustomPolicy.method(:hide_email?) # You can provide own callable object
    #
    #    attribute :email, if_value: :present? # if email.present?
    #    attribute :email, if_value: proc {|email| email.present?} # same
    #    attribute :email, if_value: proc {|email, ctx| ctx[:show_emails]} # using context
    #    attribute :email, if_value: CustomPolicy.method(:view_email?) # You can provide own callable object
    #
    #    attribute :email, unless_value: :blank? # unless email.blank?
    #    attribute :email, unless_value: proc {|email| email.blank?} # same
    #    attribute :email, unless_value: proc {|email, context| context[:show_emails]} # using context
    #    attribute :email, unless_value: CustomPolicy.method(:hide_email?) # You can provide own callable object
    #  end
    #
    module If
      # @return [Symbol] Plugin name
      def self.plugin_name
        :if
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
        require_relative "./validations/check_opt_if"
        require_relative "./validations/check_opt_if_value"
        require_relative "./validations/check_opt_unless"
        require_relative "./validations/check_opt_unless_value"

        serializer_class::SeregaMapPoint.include(MapPointInstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
        serializer_class::SeregaObjectSerializer.include(SeregaObjectSerializerInstanceMethods)
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        if serializer_class.plugin_used?(:batch)
          raise SeregaError, "Plugin `#{plugin_name}` must be loaded before `batch`"
        end
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
        serializer_class.config.attribute_keys << :if << :if_value << :unless << :unless_value
      end

      #
      # Serega::SeregaMapPoint additional/patched instance methods
      #
      # @see Serega::SeregaMapPoint::InstanceMethods
      #
      module MapPointInstanceMethods
        #
        # @return [Boolean] Should we show attribute or not
        #   Conditions for this checks are specified by :if and :unless attribute options.
        #
        def satisfy_if_conditions?(obj, ctx)
          check_if_unless(obj, ctx, :if, :unless)
        end

        #
        # @return [Boolean] Should we show attribute with specific value or not.
        #   Conditions for this checks are specified by :if_value and :unless_value attribute options.
        #
        def satisfy_if_value_conditions?(value, ctx)
          check_if_unless(value, ctx, :if_value, :unless_value)
        end

        private

        def check_if_unless(obj, ctx, opt_if_name, opt_unless_name)
          opt_if = attribute.opts[opt_if_name]
          opt_unless = attribute.opts[opt_unless_name]
          return true if opt_if.nil? && opt_unless.nil?

          res_if =
            case opt_if
            when NilClass then true
            when Symbol then obj.public_send(opt_if)
            else opt_if.call(obj, ctx)
            end

          res_unless =
            case opt_unless
            when NilClass then true
            when Symbol then !obj.public_send(opt_unless)
            else !opt_unless.call(obj, ctx)
            end

          res_if && res_unless
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

          CheckOptIf.call(opts)
          CheckOptUnless.call(opts)
          CheckOptIfValue.call(opts)
          CheckOptUnlessValue.call(opts)
        end
      end

      #
      # SeregaObjectSerializer additional/patched class methods
      #
      # @see Serega::SeregaObjectSerializer
      #
      module SeregaObjectSerializerInstanceMethods
        private

        def serialize_point(object, point, _container)
          return unless point.satisfy_if_conditions?(object, context)
          super
        end

        def attach_final_value(value, point, _container)
          return unless point.satisfy_if_value_conditions?(value, context)
          super
        end
      end
    end

    register_plugin(If.plugin_name, If)
  end
end
