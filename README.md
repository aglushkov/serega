[![Gem Version](https://badge.fury.io/rb/serega.svg)](https://badge.fury.io/rb/serega)
[![GitHub Actions](https://github.com/aglushkov/serega/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/serega/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/test_coverage)](https://codeclimate.com/github/aglushkov/serega/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/maintainability)](https://codeclimate.com/github/aglushkov/serega/maintainability)

# Serega Ruby Serializer

The Serega Ruby Serializer provides easy and powerfull DSL to describe your objects and to serialize them to Hash or JSON.

---

  📌 Serega can be used with or without any framework, it does not depend on any gem

---

It has also some great features:

- Manually [select serialized fields](#selecting-fields)
- Built-in object presenter ([presenter][presenter] plugin)
- Solution for N+1 problem (via [batch][batch], [preloads][preloads] or [activerecord_preloads][activerecord_preloads] plugins)
- Custom metadata (via [metadata][metadata] or [context_metadata][context_metadata] plugins)
- Custom attribute formatters ([formatters][formatters] plugin)

## Installation

`bundle add serega`


### Define serializers

Most apps should define base serializer with common plugins and settings to not repeat this in every serializer.
Children serializers will inherit plugins, config, attributes from parent.

```ruby
class AppSerializer < Serega
  plugin :root
  plugin :formatters
  plugin :preloads
  plugin :activerecord_preloads

  config.formatters.add(iso_time: ->(time) { time.iso8601.round(6) })
end

class UserSerializer < AppSerializer
  attribute :one
  attribute :two
  attribute :three
end
```

### Adding attributes

```ruby
class UserSerializer < Serega
  # Regular attribute
  attribute :first_name

  # Option :key specifies method in object
  attribute :first_name, key: :old_first_name

  # Block is used to define attribute value
  attribute(:first_name) { |user| user.profile&.first_name }

  # Option :value can be used with callable object to define attribute value
  attribute :first_name, value: proc { |user| user.profile&.first_name }

  # Option :delegate can be used to define attribute value. Sub-option :allow_nil by default is false
  attribute :first_name, delegate: { to: :profile, allow_nil: true }

  # Option :const specifies attribute with specific constant value
  attribute(:type, const: 'user')

  # Option :hide specifies attributes that should not be serialized by default
  attribute :tags, hide: true

  # Option :serializer specifies nested serializer for attribute
  # We can specify serializer as Class, String or Proc.
  # Use String or Proc if you have cross references in serializers.
  attribute :posts, serializer: PostSerializer
  attribute :posts, serializer: "PostSerializer"
  attribute :posts, serializer: -> { PostSerializer }

  # Option `:many` specifies a has_many relationship
  # Usually it is defined automatically by checking `is_a?(Enumerable)`
  attribute :posts, serializer: PostSerializer, many: true

  # Option `:preload` can be specified when enabled `:preloads` plugin
  # It allows to specify associations to preload to attribute value
  attribute :email, preload: :emails, value: proc { |user| user.emails.find(&:verified?) }

  # Option `:hide_nil` can be specified when enabled `:hide_nil` plugin
  # It is literally hides attribute if its value is nil
  attribute :email, hide_nil: true

  # Option `:format` can be specified when enabled `:formatters` plugin
  # It changes attribute value
  attribute :created_at, format: :iso_time
  attribute :updated_at, format: :iso_time

  # Option `:format` also can be used as Proc
  attribute :created_at, format: proc { |time| time.strftime("%Y-%m-%d")}
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

UserSerializer.to_h(user) # => {username: "serega"}
UserSerializer.to_h([user]) # => [{username: "serega"}]

UserSerializer.to_json(user) # => '{"username":"serega"}'
UserSerializer.to_json([user]) # => '[{"username":"serega"}]'

UserSerializer.as_json(user) # => {"username":"serega"}
UserSerializer.as_json([user]) # => [{"username":"serega"}]
```

---
⚠️ When you serialize `Struct` object, specify manually `many: false`. As Struct is Enumerable and we check `object.is_a?(Enumerable)` to detect if we should return array.

```ruby
  UserSerializer.to_h(user_struct, many: false)
```

### Selecting Fields

  By default all attributes are serialized (except once marked as `hide: true`).

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
# Next 3 lines are identical:
UserSerializer.to_h(bruce, only: [:username, { enemies: [:username, :email] }])
UserSerializer.new(only: [:username, { enemies: [:username, :email] }]).to_h(bruce)
UserSerializer.new(only: 'username,enemies(username,email)').to_h(bruce)
# => {:username=>"Batman", :enemies=>[{:username=>"The Joker", :email=>"joker@mail.com"}]}

# With `:except` modifier
# Next 3 lines are identical:
UserSerializer.new(except: %i[first_name last_name]).to_h(bruce)
UserSerializer.to_h(bruce, except: %i[first_name last_name])
UserSerializer.to_h(bruce, except: 'first_name,last_name')
# => {:username=>"Batman"}

# With `:with` modifier
# Next 3 lines are identical:
UserSerializer.new(with: %i[email enemies]).to_h(bruce)
UserSerializer.to_h(bruce, with: %i[email enemies])
UserSerializer.to_h(bruce, with: 'email,enemies')
# => {:username=>"Batman", :first_name=>"Bruce", :last_name=>"Wayne", :email=>"bruce@wayneenterprises.com", :enemies=>[{:username=>"The Joker", :first_name=>"jack", :last_name=>"Oswald White"}]}

# With not existing attribute
# Next 3 lines are identical:
UserSerializer.new(only: %i[first_name enemy]).to_h(bruce)
UserSerializer.to_h(bruce, only: %i[first_name enemy])
UserSerializer.to_h(bruce, only: 'first_name,enemy')
# => raises Serega::AttributeNotExist, "Attribute 'enemy' not exists"

# With not existing attribute and disabled validation
# Next 3 lines are identical:
UserSerializer.new(only: %i[first_name enemy], check_initiate_params: false).to_h(bruce)
UserSerializer.to_h(bruce, only: %i[first_name enemy], check_initiate_params: false)
UserSerializer.to_h(bruce, only: 'first_name,enemy', check_initiate_params: false)
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
  # Stores last specified number of different serializations. Serializations differ by modifiers (`:only, :except, :with`).
  config.max_cached_map_per_serializer_count = 50 # default is 0, disabled

  # With context_metadata plugin:
  config.context_metadata.key=(value) # Changes key used to add context_metadata. By default it is :meta

  # With formatters plugin:
  config.formatters.add(key => callable_value)

  # With preloads plugin:
  config.preloads.auto_preload_attributes_with_delegate = true # Default is false
  config.preloads.auto_preload_attributes_with_serializer = true # Default is false
  config.preloads.auto_hide_attributes_with_preload = true # Default is false

  # With root plugin
  config.root = { one: :data, many: :data } # Changes root values. Default is :data
  config.root.one = :user # Changes specific root value
  config.root.many = :people # Changes specific root value
end
```

## Plugins

### Plugin :preloads

Allows to define `:preloads` to attributes and then allows to merge preloads
from serialized attributes and return single associations hash.

Plugin accepts options:
- `auto_preload_attributes_with_delegate` - default false
- `auto_preload_attributes_with_serializer` - default false
- `auto_hide_attributes_with_preload` - default false

This options are very handy if you want to forget about finding preloads manually.

Preloads can be disabled with `preload: false` attribute option option.
Also automatically added preloads can be overwritten with manually specified `preload: :another_value`.

Some examples, **please read comments in the code below**

```ruby
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_delegate: true,
    auto_preload_attributes_with_serializer: true,
    auto_hide_attributes_with_preload: true
end

class UserSerializer < AppSerializer
  # No preloads
  attribute :username

  # Specify `preload: :user_stats` manually
  attribute :followers_count, preload: :user_stats, value: proc { |user| user.user_stats.followers_count }

  # Automatically `preloads: :user_stats` as `auto_preload_attributes_with_delegate` option is true
  attribute :comments_count, delegate: { to: :user_stats }

  # Automatically `preloads: :albums` as `auto_preload_attributes_with_serializer` option is true
  attribute :albums, serializer: 'AlbumSerializer'
end

class AlbumSerializer < AppSerializer
  attribute :images_count, delegate: { to: :album_stats }
end

# By default preloads are empty, as we specify `auto_hide_attributes_with_preload = true`,
# and attributes with preloads will be not serialized
UserSerializer.new.preloads # => {}
UserSerializer.new.to_h(OpenStruct.new(username: 'foo')) # => {:username=>"foo"}

UserSerializer.new(with: :followers_count).preloads # => {:user_stats=>{}}
UserSerializer.new(with: %i[followers_count comments_count]).preloads # => {:user_stats=>{}}
UserSerializer.new(with: [:followers_count, :comments_count, { albums: :images_count }]).preloads # => {:user_stats=>{}, :albums=>{:album_stats=>{}}}
```

---
One tricky case, that you will probably never see in real life:

Manually you can preload multiple associations, like this:

```ruby
attribute :image, serializer: ImageSerializer, preload: { attachment: :blob }, value: proc { |record| record.attachment }
```

In this case we mark last element (in this case it will be `blob`) as main,
so nested associations, if any, will be preloaded to this `blob`.
If you need to preload them to `attachment`,
please specify additionally `:preload_path` option like this:

```ruby
attribute :image, serializer: ImageSerializer, preload: { attachment: :blob }, preload_path: %i[attachment], value: proc { |record| record.attachment }
```
---

📌 Plugin `:preloads` only allows to group preloads together in single Hash, but they should be preloaded manually. For now there are only [activerecord_preloads][activerecord_preloads] plugin that can automatically preload associations.


### Plugin :activerecord_preloads

(depends on [preloads][preloads] plugin, that must be loaded first)

Automatically preloads associations to serialized objects.

It takes all defined preloads from serialized attributes (including attributes from serialized relations),
merges them into single associations hash and then uses ActiveRecord::Associations::Preloader
to preload associations to serialized objects.


```ruby
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_delegate: true,
    auto_preload_attributes_with_serializer: true,
    auto_hide_attributes_with_preload: false

  plugin :activerecord_preloads
end

class UserSerializer < AppSerializer
  attribute :username
  attribute :comments_count, delegate: { to: :user_stats }
  attribute :albums, serializer: AlbumSerializer
end

class AlbumSerializer < AppSerializer
  attribute :title
  attribute :downloads_count, preload: :downloads, value: proc { |album| album.downloads.count }
end

UserSerializer.to_h(user) # => preloads {users_stats: {}, albums: { downloads: {} }}
```

### Plugin :batch

Adds ability to load attributes values in batches.

It can be used to omit N+1, to calculate counters for different objects in single query, to request any data from external storage.

Added new `:batch` attribute option, example:
```
attribute :name, batch: { key: :id, loader: :name_loader, default: '' }
```

`:batch` option must be a hash with this keys:
- :key (required) [Symbol, Proc, callable] - Defines identifier of current object
- :loader (required) [Symbol, Proc, callable] - Defines how to fetch values for batch of keys. Accepts 3 parameters: keys, context, point.
- :default (optional) - Default value used when loader does not return value for current key. By default it is `nil` or `[]` when attribute has additional option `many: true` (`attribute :name, many: true, batch: { ... }`).

If `:loader` was defined via Symbol then batch loader must be defined using `config.batch_loaders.define(:loader_name) { ... }` method.
Result of this block must be a Hash where keys are - provided keys, and values are - batch loaded values for according keys.

Batch loader works well with [`activerecord_preloads`][activerecord_preloads] plugin.

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

Allows to add root key to your serialized data

Accepts options:
- :root - specifies root for all responses
- :root_one - specifies root for single object serialization only
- :root_many - specifies root for multiple objects serialization only

Adds additional config options:
- config.root.one
- config.root.many
- config.root.one=
- config.root_many=

Default root is `:data`.

Root also can be changed per serialization.

Also root can be removed for all responses by providing `root: nil`. In this case no root will be added to response, but
you still can to add it per serialization

```ruby
 #@example Define plugin

 class UserSerializer < Serega
   plugin :root # default root is :data
 end

 class UserSerializer < Serega
   plugin :root, root: :users
 end

 class UserSerializer < Serega
   plugin :root, root_one: :user, root_many: :people
 end

 class UserSerializer < Serega
   plugin :root, root: nil # no root by default
 end
```

```ruby
 # @example Change root per serialization:

 class UserSerializer < Serega
   plugin :root
 end

 UserSerializer.to_h(nil)              # => {:data=>nil}
 UserSerializer.to_h(nil, root: :user) # => {:user=>nil}
 UserSerializer.to_h(nil, root: nil)   # => nil
```

### Plugin :metadata

Depends on: [`:root`][root] plugin, that must be loaded first

Adds ability to describe metadata and adds it to serialized response

Added class-level method `:meta_attribute`, to define metadata, it accepts:
- *path [Array<Symbol>] - nested hash keys beginning from the root object.
- **options [Hash] - defaults are `hide_nil: false, hide_empty: false`
- &block [Proc] - describes value for current meta attribute

```ruby
class AppSerializer < Serega
  plugin :root
  plugin :metadata

  meta_attribute(:version) { '1.2.3' }
  meta_attribute(:ab_tests, :names) { %i[foo bar] }
  meta_attribute(:meta, :paging, hide_nil: true) do |records, ctx|
    next unless records.respond_to?(:total_count)

    { page: records.page, per_page: records.per_page, total_count: records.total_count }
  end
end

AppSerializer.to_h(nil) # => {:data=>nil, :version=>"1.2.3", :ab_tests=>{:names=>[:foo, :bar]}}
```

### Plugin :context_metadata

Depends on: [`:root`][root] plugin, that must be loaded first

Allows to provide metadata and attach it to serialized response.

Accepts option `:context_metadata_key` with name of keyword that must be used to provide metadata. By default it is `:meta`

```ruby
class UserSerializer < Serega
  plugin :root, root: :data
  plugin :context_metadata, context_metadata_key: :meta
end

UserSerializer.to_h(nil, meta: { version: '1.0.1' })
# => {:data=>nil, :version=>"1.0.1"}
```

### Plugin :formatters

Allows to define value formatters one time and apply them on any attributes.

Config option `config.formatters.add()` can be used to add formatters.

Attribute option `:format` now can be used with name of formatter or with callable instance.

```ruby
class AppSerializer < Serega
  plugin :formatters, formatters: {
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value) { value.round(2) }
  }
end

class UserSerializer < Serega
  # Additionally we can add formatters via config in subclasses
  config.formatters.add(
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value) { value.round(2) }
  )

  # Using predefined formatter
  attribute :commission, format: :money
  attribute :is_logined, format: :on_off
  attribute :created_at, format: :iso8601
  attribute :updated_at, format: :iso8601

  # Using `callable` formatter
  attribute :score_percent, format: PercentFormmatter # callable class
  attribute :score_percent, format: proc { |percent| "#{percent.round(2)}%" }
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

Allows to specify modifiers as strings.

Serialized attributes must be split with `,` and nested attributes must be defined inside brackets `(`, `)`.

Modifiers can still be provided old way with nested hashes or arrays.

```ruby
PostSerializer.plugin :string_modifiers
PostSerializer.new(only: "id,user(id,username)").to_h(post)
PostSerializer.new(except: "user(username,email)").to_h(post)
PostSerializer.new(with: "user(email)").to_h(post)

# Modifiers can still be provided old way with nested hashes or arrays.
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
[context_metadata]: #plugin-context_metadata
[formatters]: #plugin-formatters
[metadata]: #plugin-metadata
[preloads]: #plugin-preloads
[presenter]: #plugin-presenter
[root]: #plugin-root
[string_modifiers]: #plugin-string_modifiers
