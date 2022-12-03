# frozen_string_literal: true

class Serega
  #
  # Base exception class
  #
  class SeregaError < StandardError; end

  # Raised when serializer is initiated using not existing attribute
  #
  # @example
  #   Serega.new(only: 'FOO')
  #   # => Attribute 'FOO' not exists (Serega::AttributeNotExist)
  class AttributeNotExist < SeregaError; end
end
