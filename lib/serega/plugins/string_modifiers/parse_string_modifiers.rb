# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module StringModifiers
      class ParseStringModifiers
        COMMA = ","
        OPEN_BRACKET = "("
        CLOSE_BRACKET = ")"

        def self.call(fields)
          return fields unless fields.is_a?(String)

          new.parse(fields)
        end

        # user => { user: {} }
        # user(id) => { user: { id: {} } }
        # user(id,name) => { user: { id: {}, name: {} } }
        # user,comments => { user: {}, comments: {} }
        # user(comments(text)) => { user: { comments: { text: {} } } }
        def parse(fields)
          res = {}
          attribute = +""
          path_stack = nil

          fields.each_char do |char|
            case char
            when COMMA
              add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
            when CLOSE_BRACKET
              add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
              path_stack&.pop
            when OPEN_BRACKET
              name = add_attribute(res, path_stack, attribute, {})
              (path_stack ||= []).push(name) if name
            else
              attribute.insert(-1, char)
            end
          end

          add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)

          res
        end

        private

        def add_attribute(res, path_stack, attribute, nested_attributes = FROZEN_EMPTY_HASH)
          attribute.strip!
          return if attribute.empty?

          name = attribute.to_sym
          attribute.clear

          current_attrs = (!path_stack || path_stack.empty?) ? res : res.dig(*path_stack)
          current_attrs[name] = nested_attributes

          name
        end
      end
    end
  end
end
