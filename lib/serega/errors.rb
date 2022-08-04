# frozen_string_literal: true

class Serega
  # A generic exception Serega uses.
  class SeregaError < StandardError; end

  # AttributeNotExist is raised when serializer is initiated using not existing attribute
  # Example:
  #    UserSerializer.new(only: 'FOO', except: 'FOO', with: 'FOO')
  #    UserSerializer.to_h(user, only: 'FOO', except: 'FOO', with: 'FOO' )
  class AttributeNotExist < SeregaError; end
end
