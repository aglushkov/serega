# frozen_string_literal: true

require "stringio"

class Serega
  module SeregaPlugins
    #
    # Plugin :string_modifiers
    #
    # Allows to specify modifiers as strings.
    #
    # Serialized attributes must be split with `,` and nested attributes can be defined inside brackets `(`, `)`.
    #
    # @example
    #   PostSerializer.plugin :string_modifiers
    #   PostSerializer.new(only: "id,user(id,username)").to_h(post)
    #   PostSerializer.new(except: "user(username,email)").to_h(post)
    #   PostSerializer.new(with: "user(email)").to_h(post)
    #
    #   # Modifiers can still be provided old way with nested hashes or arrays.
    #   PostSerializer.new(with: {user: %i[email, username]}).to_h(post)
    #
    module StringModifiers
      #
      # Modifiers parser
      #
      class ParseStringModifiers
        #
        # Parses provided fields
        #
        # @param fields [String,Hash,Array,nil]
        #
        # @return [Hash] parsed modifiers in form of nested hash
        #
        def self.call(fields)
          return fields unless fields.is_a?(String)

          new.parse(fields)
        end

        #
        # Parses string modifiers
        #
        # @param fields [String]
        #
        # @return [Hash] parsed modifiers in form of nested hash
        #
        # @example
        #   parse("user") => { user: {} }
        #   parse("user(id)") => { user: { id: {} } }
        #   parse("user(id,name)") => { user: { id: {}, name: {} } }
        #   parse("user,comments") => { user: {}, comments: {} }
        #   parse("user(comments(text))") => { user: { comments: { text: {} } } }
        def parse(fields)
          res = {}
          attribute = +""
          char = +""
          path_stack = nil
          fields = StringIO.new(fields)

          while fields.read(1, char)
            case char
            when ","
              add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
            when ")"
              add_attribute(res, path_stack, attribute, FROZEN_EMPTY_HASH)
              path_stack&.pop
            when "("
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
