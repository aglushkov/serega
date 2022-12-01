[![Gem Version](https://badge.fury.io/rb/serega.svg)](https://badge.fury.io/rb/serega)
[![GitHub Actions](https://github.com/aglushkov/serega/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/serega/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/test_coverage)](https://codeclimate.com/github/aglushkov/serega/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/maintainability)](https://codeclimate.com/github/aglushkov/serega/maintainability)

# Serega Ruby Serializer

The Serega Ruby Serializer provides easy and powerfull DSL to describe your objects and to serialize them to Hash or JSON.

It has also some great features:

- Manually [select serialized fields](#selecting-fields)
- Built-in object presenter ([presenter][presenter] plugin)
- Solution for N+1 problem (via [batch][batch], [preloads][preloads] or [activerecord_preloads][activerecord_preloads] plugins)
- Custom metadata (via [metadata][metadata] or [context_metadata][context_metadata] plugins)
- Custom attribute formatters ([formatters][formatters] plugin)

## Installation

```
  bundle add serega
```

  📌 Serega can be used with or without ANY framework

## Cheat Sheet

### Define serializers

```ruby
# Add base serializer to specify common plugins, settings, probably some attributes
class AppSerializer < Serega
  # default plugins
  # default config values
  # default attributes
  # ...
end

# Children serializers inherit attributes, settings, plugins from parent serializer
class UserSerializer < AppSerializer
  attribute :id
  attribute :username
  attribute :email, hide: true
end

class PostSerializer < AppSerializer
  attribute :id
  attribute :text

  attribute :user, serializer: UserSerializer
end
```

### Serializing

We can serialize objects using class methods `.to_h`, `.to_json`, `.as_json` and same instance methods `#to_h`, `#to_json`, `#as_json`.
`to_h` method is also aliased as `call`.

```ruby
user = OpenStruct.new(username: 'serega')

class UserSerializer < Serega
  attribute :username
end

UserSerializer.(user) # => {username: "serega"}
UserSerializer.to_h(user) # => {username: "serega"}
UserSerializer.to_json(user) # => '{"username":"serega"}'
UserSerializer.as_json(user) # => {"username" => "serega"}

# We can provide additional params when instantiating serializer, examples will be below
UserSerializer.new.(user) # => {username: "serega"}
UserSerializer.new.to_h(user) # => {username: "serega"}
UserSerializer.new.to_json(user) # => '{"username":"serega"}'
UserSerializer.new.as_json(user) # => {"username" => "serega"}
```

### Serializing Arrays

Any `Enumerable` data is serialized to `Array` by default. Data can be an Array, ActiveRecord::Relation, Kaminari::PaginatableArray, etc.
We check if serializable data `is_a?(Enumerable)` when deciding to construct array. But sometimes this gives incorrect behavior, for example with `Struct`, as it is also `Enumerable`.
In this case we can manually specify `many: false`.

```ruby
user = Struct.new(:username).new('struct_user')

class UserSerializer < Serega
  attribute :username
end

array = [user, user]

UserSerializer.(array) # => [{username: "struct_user"}, {username: "struct_user"}]
UserSerializer.(user, many: false) # => {username: "struct_user"}
UserSerializer.new.to_h(user, many: false) # same
```

### Defining attributes

```ruby
class UserSerializer < Serega
  # Regular attribute
  attribute :first_name

  # Option :key specifies method in object
  attribute :first_name, key: :old_first_name

  # Block is used to define attribute value
  attribute(:first_name) { |user| user.profile&.first_name }

  # Option :value can be used with callable object to define attribute value
  attribute :first_name, value: proc { |user| user.profile&.first_name } # by providing callable :value option

  # Option :delegate can be used to define attribute value. Sub-option :allow_nil by default is false
  attribute :first_name, delegate: { to: :profile, allow_nil: true }

  # Option :const specifies attribute with specific constant value
  attribute(:type, const: 'user')

  # Option :hide specifies attributes that should not be serialized by default
  attribute :tags, hide: true

  # Option :serializer specifies nested serializer for attribute
  # We can specify serializer as Class, String or Proc.
  attribute :posts, serializer: PostSerializer
  attribute :posts, serializer: "PostSerializer"
  attribute :posts, serializer: -> { PostSerializer }

  # Option `:many` specifies a has_many relationship
  # Usually it is defined automatically by checking `is_a?(Enumerable)`
  attribute :posts, serializer: PostSerializer, many: true

  # Option `:preload` can be specified when enabled `:preloads` or `:activerecord_preloads` plugin
  # It allows to specify what should be preloaded to serialized attribute
  plugin :preloads # or activerecord_preloads
  attribute :email, preload: :emails, value: proc { |user| user.emails.find(&:verified?) }

  # Option `:hide_nil` can be specified when enabled `:hide_nil` plugin
  # It is literally hides attribute if its value is nil
  plugin :hide_nil
  attribute :email, hide_nil: true

  # Option `:format` can be specified when enabled `:formatters` plugin
  # It changes attribute value
  config.formatters.add(iso_time: ->(time) { time.iso8601.round(6) })
  attribute :created_at, format: :iso_time
  attribute :updated_at, format: :iso_time

  # Option `:format` also can be used as Proc
  attribute :created_at, format: proc { |time| time.strftime("%Y-%m-%d")}
end
```

### Selecting Fields
  By default all attributes are serialized.
  We can provide **modifiers** to select only needed attributes:

  - *only* - lists attributes to serialize;
  - *except* - lists attributes to not serialize;
  - *with* - lists attributes to serialize additionally (By default all attributes are exposed and will be serialized, but some attributes can be hidden when they are defined with `hide: true` option, more on this below. `with` modifier can be used to show such attributes).

  Modifiers can be provided as Hash, Array, String, Symbol or their combinations.

  With plugin [string_modifiers][string_modifiers] we can provide modifiers as single `String` with attributes split by comma `,` and nested values inside brackets `()`, like: `username,enemies(username,email)`. This can be very useful to accept list of field in **GET** requests.

  When provided non-existing attribute, `Serega::AttributeNotExist` error will be raised, but it can be muted with `check_initiate_params: false` parameter.

```ruby
class UserSerializer < Serega
  plugin :string_modifiers # to send all modifiers in one string

  attribute :username
  attribute :first_name
  attribute :last_name
  attribute :email, hide: true
  attribute :enemies, serializer: UserSerializer, hide: true
end

joker = OpenStruct.new(username: 'The Joker', first_name: 'jack', last_name: 'Oswald White', email: 'joker@mail.com', enemies: [])
bruce = OpenStruct.new(username: 'Batman', first_name: 'Bruce', last_name: 'Wayne', email: 'bruce@wayneenterprises.com', enemies: [])
joker.enemies << bruce
bruce.enemies << joker

# Default
UserSerializer.to_h(bruce) # => {:username=>"Batman", :first_name=>"Bruce", :last_name=>"Wayne"}

# With `:only` modifier
UserSerializer.new(only: [:username, { enemies: [:username, :email] }]).to_h(bruce)
UserSerializer.to_h(bruce, only: [:username, { enemies: [:username, :email] }]) # => same
UserSerializer.new(only: 'username,enemies(username,email)').to_h(bruce) # same, using `string_modifiers` plugin
# => {:username=>"Batman", :enemies=>[{:username=>"The Joker", :email=>"joker@mail.com"}]}

# With `:except` modifier
UserSerializer.new(except: %i[first_name last_name]).to_h(bruce)
UserSerializer.to_h(bruce, except: %i[first_name last_name]) # same
UserSerializer.to_h(bruce, except: 'first_name,last_name') # same, using `string_modifiers` plugin
# => {:username=>"Batman"}

# With `:with` modifier
UserSerializer.new(with: %i[email enemies]).to_h(bruce)
UserSerializer.to_h(bruce, with: %i[email enemies]) # same
UserSerializer.to_h(bruce, with: 'email,enemies') # same, using `string_modifiers` plugin
# => {:username=>"Batman", :first_name=>"Bruce", :last_name=>"Wayne", :email=>"bruce@wayneenterprises.com", :enemies=>[{:username=>"The Joker", :first_name=>"jack", :last_name=>"Oswald White"}]}

# With not existing attribute
UserSerializer.new(only: %i[first_name enemy]).to_h(bruce)
UserSerializer.to_h(bruce, only: %i[first_name enemy]) # same
UserSerializer.to_h(bruce, only: 'first_name,enemy') # same, using `string_modifiers` plugin
# => raises Serega::AttributeNotExist, "Attribute 'enemy' not exists"

# With not existing attribute and disabled validation
UserSerializer.new(only: %i[first_name enemy], check_initiate_params: false).to_h(bruce)
UserSerializer.to_h(bruce, only: %i[first_name enemy], check_initiate_params: false) # same
UserSerializer.to_h(bruce, only: 'first_name,enemy', check_initiate_params: false) # same, using `string_modifiers` plugin
# => {:first_name=>"Bruce"}
```

### Using Context

Sometimes you can decide to use some context during serialization, like current_user or any.

```ruby
class UserSerializer < Serega
  attribute(:email) do |user, ctx|
    user.email if ctx[:current_user] == user
  end
end

user = OpenStruct.new(email: 'email@example.com')
UserSerializer.(user, context: {current_user: user}) # => {:email=>"email@example.com"}
UserSerializer.new.to_h(user, context: {current_user: user}) # same
```

## Configuration

```ruby
class AppSerializer < Serega
  # Configure adapter to serialize to JSON.
  # It is `JSON.dump` by default. When Oj gem is loaded then default is `Oj.dump(data, mode: :compat)`
  config.to_json = ->(data) { Oj.dump(data, mode: :compat) }

  # Configure adapter to de-serialize JSON. De-serialization is used only for `#as_json` method.
  # It is `JSON.parse` by default. When Oj gem is loaded then default is `Oj.load(data)`
  config.from_json = ->(data) { Oj.load(data) }

  # Disable/enable validation of modifiers params `:with`, `:except`, `:only`
  # By default it is enabled. After disabling, when provided not existed attribute it will be just skipped.
  config.check_initiate_params = false # default is true, enabled

  # Stores serialized attributes in class instance variables
  # This way we can reuse some calculated data from previous serialization.
  # Stores them for last N(count) different serializations. Serializations differ by modifiers (`:only, :except, :with`).
  config.max_cached_map_per_serializer_count = 50 # default is 0, disabled

  # With context_metadata plugin:
  config.context_metadata.key=(value) # Changes key used to add context_metadata. By default it is :meta

  # With formatters plugin:
  config.formatters.add(key => callable_value)

  # With preloads plugin:
  # We can configure to automatically hide some attributes or automatically add preloads
  config.preloads.auto_preload_attributes_with_delegate = true # Default is false
  config.preloads.auto_preload_attributes_with_serializer = true # Default is false
  config.preloads.auto_hide_attributes_with_preload = true # Default is false

  # With root plugin
  config.root = { one: 'data', many: 'data' } # Changes root values. Default is `data`
  config.root.one = 'user' # Changes specific root value
  config.root.many = 'users' # Changes specific root value
end
```

## Plugins

### Plugin :preloads

Allows to find `preloads` for current serializer. It merges **only** preloads specified in currently serialized attributes, skipping preloads of not serialized attributes.

Preloads can be fetched using `MySerializer.preloads` or `MySerializer.new(modifiers_opts).preloads` methods.

Config option `config.preloads.auto_preload_attributes_with_serializer = true` can be specified to automatically add `preload: <attribute_key>` to all attributes with `:serializer` option.

Config option `config.preloads.auto_preload_attributes_with_delegate = true` can be specified to automatically add `preload: <delegate_to>` to all attributes with `:delegate` option.

Config option `config.preloads.auto_hide_attributes_with_preload = true` can be specified to automatically add `hide: true` to all attributes with any `:preload`. It also works for automatically assigned preloads.

Preloads can be disabled with `preload: false` option. Also auto added preloads can be overwritten with `preload: <another_key>` option.

```ruby
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_serializer: true,
    auto_preload_attributes_with_delegate: true,
    auto_hide_attributes_with_preload: true
end

class PostSerializer < AppSerializer
  attribute :views_count, preload: :views_stats, value: proc { |post| post.views_stats.views_count  }
  attribute :user, serializer: 'UserSerializer'
end

class UserSerializer  < AppSerializer
  attribute :followers_count, delegate: {to: :user_stats}
end

PostSerializer.new(only: [:views_count, user: :followers_count]).preloads # => {:views_stats=>{}, :user=>{:user_stats=>{}}}
```

### Plugin :activerecord_preloads

Automatically preloads everything specified in `:preload` attributes options to serialized object during
serialization

```ruby
class AppSerializer < Serega
  plugin :activerecord_preloads, # also adds :preloads plugin automatically
    auto_preload_attributes_with_delegate: true,
    auto_preload_attributes_with_serializer: true,
    auto_hide_attributes_with_preload: true
end
```

### Plugin :batch

Adds ability to load attributes values in batches.

It can be used to omit N+1, to calculate counters for different objects in single query, to request any data from external storage.

Added new attribute option :batch, ex: `attribute :name, batch: { keys: ..., loader: ..., default: ...}`.

`:batch` option must be a hash with this keys:
- :key (required) [Symbol, Proc, callable] - Defines identifier of current object
- :loader (required) [Symbol, Proc, callable] - Defines how to fetch values for batch of keys. Accepts 3 parameters: keys, context, point.
- :default (optional) - Default value used when loader does not return value for current key. By default it is `nil` or `[]` when attribute has additional option `many: true` (`attribute :name, many: true, batch: { ... }`).

If `:loader` was defined via Symbol then batch loader must be defined using `config.batch_loaders.define(:loader_name) { ... }` method.
Result of this block must be a Hash with provided keys.

Batch loader works well with [`activerecord_preloads`][plugin-activerecord_preloads] plugin.

```ruby
class PostSerializer < Serega
  plugin :batch

  # Define batch loader via callable class, it must accept three args (keys, context, nested_attributes)
  attribute :comments_count, batch: { key: :id, loader: PostCommentsCountBatchLoader, default: 0}

  # Define batch loader via Symbol, later we should define this loader via config.batch_loaders.define(:posts_comments_counter) { ... }
  attribute :comments_count, batch: { key: :id, loader: :posts_comments_counter, default: 0}

  # Define batch loader with serializer
  attribute :comments, serializer: CommentSerializer, batch: { key: :id, loader: :posts_comments, default: []}

  # Resulted block must return hash like { key => value(s) }
  config.batch_loaders.define(:posts_comments_counter) do |keys|
    Comment.group(:post_id).where(post_id: keys).count
  end

  # We can return objects that will be automatically serialized if attribute defined with :serializer
  # Parameter `context` can be used when loading batch
  # Parameter `point` can be used to find nested attributes  that will be serialized
  config.batch_loaders.define(:posts_comments) do |keys, context, point|
    # point.nested_points - if you need to manually check all nested attributes that will be serialized
    # point.preloads - if you need to find nested preloads (works with :preloads plugin only)

    Comment
      .preload(point.preloads) # Can be skipped when used :activerecord_preloads plugin
      .where(post_id: keys)
      .where(is_spam: false)
      .group_by(&:post_id)
  end
end
```

### Plugin :root

Wraps serialized response in additional hash with specified `root` key.

```ruby
class AppSerializer < Serega
  plugin :root, root: :data # :data is also a default value for root
end

# Any serialized hash will look like this
# { data: <original_hash> }
```

Allows to specify different root keys for single record or for multiple serialized records

```ruby
class UserSerializer < Serega
  plugin :root, one: :user, many: :users
end

# Any serialized hash:
# => { user: <original_hash> } or { users: <original_array> }
```

### Plugin :metadata

Allows to add `meta_attribute` to serializers. Meta attributes

```ruby
class AppSerializer < Serega
  plugin :metadata

  # def meta_attribute(*path, **options, &block)
  meta_attribute(:version) { '1.0.0' }
  meta_attribute(:meta, :paging, hide_nil: true) do |records, context|
    break unless context.dig(:params, :page)
    break unless records.is_a?(Enumerable)
    break unless records.respond_to?(:total_count)

    {
      total_count: records.total_count,
      size: records.size,
      offset_value: records.offset_value
    }
  end
end

# Any serialized hash:
# => { data: <original_hash>, version: '1.0.0', meta: { paging: ... } }
```

### Plugin :context_metadata

Allows to specify metadata when serializing objects

```ruby
class UserSerializer < Serega
  plugin :context_metadata, key: :meta # :meta is default key, it must be used when specifying custom metadata
end

# Here we use same :meta key
UserSerializer.to_h(user, meta: { version: '1.0.1' })
# => { data: <original_hash>, version: '1.0.1'}
```

### Plugin :formatters

Allows to specify and use formatters for values.
With help of formatters we can change how to present any value.

```ruby
class UserSerializer < Serega
  plugin :formatters, formatters: {
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value) { value.round(2) }
  }

  # We can add formatters via config later or in subclasses
  config.formatters.add(
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value) { value.round(2) }
  )

  attribute :commission, format: :money
  attribute :is_logined, format: :on_off
  attribute :created_at, format: :iso8601
  attribute :updated_at, format: :iso8601
end
```

### Plugin :presenter

Sometimes code will be clear when using `:presenter` plugin so we can define some complex logic there

```ruby
class UserSerializer < Serega
  plugin :presenter

  attribute :name

  class Presenter
    def name
      [first_name, last_name].compact_blank.join(' ')
    end
  end
end
```

### Plugin :string_modifiers

Allows to specify modifiers as strings, when attributes are split with `,` and nested attributes can be defined inside brackets `(`, `)`.

```ruby
PostSerializer.plugin :string_modifiers
PostSerializer.new(only: "id,user(id,username)").to_h(post)
PostSerializer.new(except: "user(username,email)").to_h(post)
PostSerializer.new(with: "user(email)").to_h(post)

# Modifiers can still be provided old way with nested hashes or arrays/
PostSerializer.new(with: {user: %i[email, username]}).to_h(post)
```

### Plugin :hide_nil

Allows to hide attributes which values are nil

```ruby
class UserSerializer < Serega
  plugin :hide_nil

  attribute :email, hide_nil: true
end
```

## Errors

- `Serega::SeregaError` is a base error raised by this gem.
- `Serega::AttributeNotExist` error is raised when validating attributes in `:only, :except, :with` modifiers

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`.

To release a new version, read [RELEASE.md](https://github.com/aglushkov/serega/blob/master/RELEASE.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aglushkov/serega.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


Links
-----

[activerecord_preloads]: #plugin-activerecord_preloads
[batch]: #plugin-batch
[context_metadata]: #plugin-context_metadata
[formatters]: #plugin-formatters
[metadata]: #plugin-metadata
[preloads]: #plugin-preloads
[presenter]: #plugin-presenter
[string_modifiers]: #plugin-string_modifiers
