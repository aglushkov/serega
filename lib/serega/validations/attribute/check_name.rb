# frozen_string_literal: true

class Serega
  module Validations
    module Attribute
      class CheckName
        FORMAT_ONE_CHAR = /\A[a-zA-Z0-9]\z/
        FORMAT_MANY_CHARS = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*?[a-zA-Z0-9]\z/ # allow '-' and '_' in the middle

        private_constant :FORMAT_ONE_CHAR, :FORMAT_MANY_CHARS

        class << self
          #
          # Checks allowed characters.
          # Globally allowed characters: "a-z", "A-Z", "0-9".
          # Minus and low line "-", "_" also allowed except as the first or last character.
          #
          # @param name [String, Symbol] Attribute name
          #
          # @raise [Error] when name has invalid format
          # @return [void]
          #
          def call(name)
            name = name.to_s

            valid =
              case name.size
              when 0 then false
              when 1 then name.match?(FORMAT_ONE_CHAR)
              else name.match?(FORMAT_MANY_CHARS)
              end

            return if valid

            raise Error, message(name)
          end

          private

          def message(name)
            %(Invalid attribute name = #{name.inspect}. Globally allowed characters: "a-z", "A-Z", "0-9". Minus and low line "-", "_" also allowed except as the first or last character)
          end
        end
      end
    end
  end
end
