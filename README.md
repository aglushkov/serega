[![Gem Version](https://badge.fury.io/rb/serega.svg)](https://badge.fury.io/rb/serega)
[![GitHub Actions](https://github.com/aglushkov/serega/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/serega/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/test_coverage)](https://codeclimate.com/github/aglushkov/serega/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/maintainability)](https://codeclimate.com/github/aglushkov/serega/maintainability)

# Serega Ruby Serializer

The Serega Ruby Serializer provides easy and powerful DSL to describe your
objects and serialize them to Hash or JSON.

---

  📌 Serega does not depend on any gem and works with any framework

---

It has some great features:

- Manually [select serialized fields](#selecting-fields)
- Secure from malicious queries with [depth_limit][depth_limit] plugin
- Solutions for N+1 problem (via [batch][batch], [preloads][preloads] or
  [activerecord_preloads][activerecord_preloads] plugins)
- Built-in object presenter ([presenter][presenter] plugin)
- Adding custom metadata (via [metadata][metadata] or
  [context_metadata][context_metadata] plugins)
- Value formatters ([formatters][formatters] plugin) helps to transform
  time, date, money, percentage, and any other values in the same way keeping
  the code dry
- Conditional attributes - ([if][if] plugin)
- Auto camelCase keys - [camel_case][camel_case] plugin

## Installation

`bundle add serega`

### Define serializers

Most apps should define **base serializer** with common plugins and settings to
not repeat them in each serializer.

Serializers will inherit everything (plugins, config, attributes) from their
superclasses.

```ruby
class AppSerializer < Serega
  # plugin :one
  # plugin :two

  # config.one = :one
  # config.two = :two
end

class UserSerializer < AppSerializer
  # attribute :one
  # attribute :two
end

class CommentSerializer < AppSerializer
  # attribute :one
  # attribute :two
end
```

### Adding attributes

```ruby
class UserSerializer < Serega
  # Regular attribute
  attribute :first_name

  # Option :method specifies the method that must be called on the serialized object
  attribute :first_name, method: :old_first_name

  # Block is used to define attribute value
  attribute(:first_name) { |user| user.profile&.first_name }

  # Option :value can be used with a Proc or callable object to define attribute
  # value
  attribute :first_name, value: UserProfile.new # must have #call method
  attribute :first_name, value: proc { |user| user.profile&.first_name }

  # Option :delegate can be used to define attribute value.
  # Sub-option :allow_nil by default is false
  attribute :first_name, delegate: { to: :profile, allow_nil: true }

  # Option :delegate can be used with :method sub-option, so method chain here
  # is user.profile.fname
  attribute :first_name, delegate: { to: :profile, method: :fname }

  # Option :default can be used to replace possible nil values.
  attribute :first_name, default: ''
  attribute :is_active, default: false
  attribute :comments_count, default: 0

  # Option :const specifies attribute with a specific constant value
  attribute(:type, const: 'user')

  # Option :hide specifies attributes that should not be serialized by default
  attribute :tags, hide: true

  # Option :serializer specifies nested serializer for attribute
  # We can define the `:serializer` value as a Class, String, or Proc.
  # Use String or Proc if you have cross-references in serializers.
  attribute :posts, serializer: PostSerializer
  attribute :posts, serializer: "PostSerializer"
  attribute :posts, serializer: -> { PostSerializer }

  # Option `:many` specifies a has_many relationship. It is optional.
  # If not specified, it is defined during serialization by checking `object.is_a?(Enumerable)`
  # Also the `:many` changes the default value from `nil` to `[]`.
  attribute :posts, serializer: PostSerializer, many: true

  # Option `:preload` can be specified when enabled `:preloads` plugin
  # It allows to specify associations to preload to attribute value
  attribute(:email, preload: :emails) { |user| user.emails.find(&:verified?) }

  # Options `:if, :unless, :if_value and :unless_value` can be specified
  # when `:if` plugin is enabled. They hide the attribute key and value from the
  # response.
  # See more usage examples in the `:if` plugin section.
  attribute :email, if: proc { |user, ctx| user == ctx[:current_user] }
  attribute :email, if_value: :present?

  # Option `:format` can be specified when enabled `:formatters` plugin
  # It changes the attribute value
  attribute :created_at, format: :iso_time
  attribute :updated_at, format: :iso_time

  # Option `:format` also can be used as Proc
  attribute :created_at, format: proc { |time| time.strftime("%Y-%m-%d")}
end
```

---

⚠️ Attribute names are checked to include only "a-z", "A-Z", "0-9", "\_", "-",
"~" characters.

We allow ONLY these characters as we want to be able to use attribute names in
URLs without escaping.

The check can be turned off:

```ruby
# Disable globally
Serega.config.check_attribute_name = false

# Disable for specific serializer
class SomeSerializer < Serega
  config.check_attribute_name = false
end
```

### Serializing

We can serialize objects using class methods `.to_h`, `.to_json`, `.as_json` and
same instance methods `#to_h`, `#to_json`, `#as_json`.
The `to_h` method is also aliased as `call`.

```ruby
user = OpenStruct.new(username: 'serega')

class UserSerializer < Serega
  attribute :username
end

UserSerializer.to_h(user) # => {username: "serega"}
UserSerializer.to_h([user]) # => [{username: "serega"}]

UserSerializer.to_json(user) # => '{"username":"serega"}'
UserSerializer.to_json([user]) # => '[{"username":"serega"}]'

UserSerializer.as_json(user) # => {"username":"serega"}
UserSerializer.as_json([user]) # => [{"username":"serega"}]
```

If serialized fields are constant, then it's a good idea to initiate the
serializer and reuse it.
It will be a bit faster (the serialization plan will be prepared only once).

```ruby
# Example with all fields
serializer = UserSerializer.new
serializer.to_h(user1)
serializer.to_h(user2)

# Example with custom fields
serializer = UserSerializer.new(only: [:username, :avatar])
serializer.to_h(user1)
serializer.to_h(user2)
```

---
⚠️ When you serialize the `Struct` object, specify manually `many: false`. As Struct
is Enumerable and we check `object.is_a?(Enumerable)` to detect if we should
return array.

```ruby
UserSerializer.to_h(user_struct, many: false)
```

### Selecting Fields

By default, all attributes are serialized (except marked as `hide: true`).

We can provide **modifiers** to select serialized attributes:

- *only* - lists specific attributes to serialize;
- *except* - lists attributes to not serialize;
- *with* - lists attributes to serialize additionally (By default all attributes
  are exposed and will be serialized, but some attributes can be hidden when
  they are defined with the `hide: true` option, more on this below. `with`
  modifier can be used to expose such attributes).

Modifiers can be provided as Hash, Array, String, Symbol, or their combinations.

With plugin [string_modifiers][string_modifiers] we can provide modifiers as
single `String` with attributes split by comma `,` and nested values inside
brackets `()`, like: `username,enemies(username,email)`. This can be very useful
to accept the list of fields in **GET** requests.

When a non-existing attribute is provided, the `Serega::AttributeNotExist` error
will be raised. This error can be muted with the `check_initiate_params: false`
option.

```ruby
class UserSerializer < Serega
  plugin :string_modifiers # to send all modifiers in one string

  attribute :username
  attribute :first_name
  attribute :last_name
  attribute :email, hide: true
  attribute :enemies, serializer: UserSerializer, hide: true
end

joker = OpenStruct.new(
  username: 'The Joker',
  first_name: 'jack',
  last_name: 'Oswald White',
  email: 'joker@mail.com',
  enemies: []
)

bruce = OpenStruct.new(
  username: 'Batman',
  first_name: 'Bruce',
  last_name: 'Wayne',
  email: 'bruce@wayneenterprises.com',
  enemies: []
)

joker.enemies << bruce
bruce.enemies << joker

# Default
UserSerializer.to_h(bruce)
# => {:username=>"Batman", :first_name=>"Bruce", :last_name=>"Wayne"}

# With `:only` modifier
fields = [:username, { enemies: [:username, :email] }]
fields_as_string = 'username,enemies(username,email)'

UserSerializer.to_h(bruce, only: fields)
UserSerializer.new(only: fields).to_h(bruce)
UserSerializer.new(only: fields_as_string).to_h(bruce)
# =>
# {
#   :username=>"Batman",
#   :enemies=>[{:username=>"The Joker", :email=>"joker@mail.com"}]
# }

# With `:except` modifier
fields = %i[first_name last_name]
fields_as_string = 'first_name,last_name'
UserSerializer.new(except: fields).to_h(bruce)
UserSerializer.to_h(bruce, except: fields)
UserSerializer.to_h(bruce, except: fields_as_string)
# => {:username=>"Batman"}

# With `:with` modifier
fields = %i[email enemies]
fields_as_string = 'email,enemies'
UserSerializer.new(with: fields).to_h(bruce)
UserSerializer.to_h(bruce, with: fields)
UserSerializer.to_h(bruce, with: fields_as_string)
# =>
# {
#   :username=>"Batman",
#   :first_name=>"Bruce",
#   :last_name=>"Wayne",
#   :email=>"bruce@wayneenterprises.com",
#   :enemies=>[
#     {:username=>"The Joker", :first_name=>"jack", :last_name=>"Oswald White"}
#   ]
# }

# With no existing attribute
fields = %i[first_name enemy]
fields_as_string = 'first_name,enemy'
UserSerializer.new(only: fields).to_h(bruce)
UserSerializer.to_h(bruce, only: fields)
UserSerializer.to_h(bruce, only: fields_as_string)
# => raises Serega::AttributeNotExist

# With no existing attribute and disabled validation
fields = %i[first_name enemy]
fields_as_string = 'first_name,enemy'
UserSerializer.new(only: fields, check_initiate_params: false).to_h(bruce)
UserSerializer.to_h(bruce, only: fields, check_initiate_params: false)
UserSerializer.to_h(bruce, only: fields_as_string, check_initiate_params: false)
# => {:first_name=>"Bruce"}
```

### Using Context

Sometimes it can be required to use the context during serialization, like
current_user or any.

```ruby
class UserSerializer < Serega
  attribute(:email) do |user, ctx|
    user.email if ctx[:current_user] == user
  end
end

user = OpenStruct.new(email: 'email@example.com')
UserSerializer.(user, context: {current_user: user})
# => {:email=>"email@example.com"}

UserSerializer.new.to_h(user, context: {current_user: user}) # same
# => {:email=>"email@example.com"}
```

## Configuration

Here are the default options. Other options can be added with plugins.

```ruby
class AppSerializer < Serega
  # Configure adapter to serialize to JSON.
  # It is `JSON.dump` by default. But if the Oj gem is loaded, then the default
  # is changed to `Oj.dump(data, mode: :compat)`
  config.to_json = ->(data) { Oj.dump(data, mode: :compat) }

  # Configure adapter to de-serialize JSON.
  # De-serialization is used only for the `#as_json` method.
  # It is `JSON.parse` by default.
  # When the Oj gem is loaded, then the default is `Oj.load(data)`
  config.from_json = ->(data) { Oj.load(data) }

  # Disable/enable validation of modifiers (`:with, :except, :only`)
  # By default, this validation is enabled.
  # After disabling, all requested incorrect attributes will be skipped.
  config.check_initiate_params = false # default is true, enabled

  # Stores in memory prepared `plans` - list of serialized attributes.
  # Next time serialization happens with the same modifiers (`only, except, with`),
  # we will reuse already prepared `plans`.
  # This defines storage size (count of stored `plans` with different modifiers).
  config.max_cached_plans_per_serializer_count = 50 # default is 0, disabled
end
```

## Plugins



## Errors

- The `Serega::SeregaError` is a base error raised by this gem.
- The `Serega::AttributeNotExist` error is raised when validating attributes in
  `:only, :except, :with` modifiers. This error contains additional methods:

   - `#serializer` - shows current serializer
   - `#attributes` - lists not existing attributes

## Release

To release a new version, read [RELEASE.md](https://github.com/aglushkov/serega/blob/master/RELEASE.md).

## Development

- `bundle install` - install dependencies
- `bin/console` - open irb console with loaded gems
- `bundle exec rspec` - run tests
- `bundle exec rubocop` - check code standards
- `yard stats --list-undoc --no-cache` - view undocumented code
- `yard server --reload` - view code documentation

## Contributing

Bug reports, pull requests and improvements ideas are very welcome!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[activerecord_preloads]: #plugin-activerecord_preloads
[batch]: #plugin-batch
[camel_case]: #plugin-camel_case
[context_metadata]: #plugin-context_metadata
[depth_limit]: #plugin-depth_limit
[formatters]: #plugin-formatters
[metadata]: #plugin-metadata
[preloads]: #plugin-preloads
[presenter]: #plugin-presenter
[root]: #plugin-root
[string_modifiers]: #plugin-string_modifiers
[if]: #plugin-if
