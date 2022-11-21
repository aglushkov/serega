[![Gem Version](https://badge.fury.io/rb/serega.svg)](https://badge.fury.io/rb/serega)
[![GitHub Actions](https://github.com/aglushkov/serega/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/serega/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/test_coverage)](https://codeclimate.com/github/aglushkov/serega/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/maintainability)](https://codeclimate.com/github/aglushkov/serega/maintainability)

# Serega Ruby Serializer

  The Serega Ruby Serializer provides easy and powerfull DSL to describe your objects and to serialize them to Hash or JSON.

  It has also some great features:
  
  - Manually select serialized fields
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

### How to create serializers
  ```ruby
    # Add base serializer to specify common plugins, config, probably some attributes
    class AppSerializer < Serega
      # default plugins
      # default config values
      # default attributes
      # ...
    end

    # Serializers inherit all configuration from parent serializer
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

### How to serialize
  We can serialize objects using `call (aliased as to_h)`, `to_json`, `as_json` methods:
  ```ruby
    user = OpenStruct.new(username:'serega')

    class UserSerializer < Serega
      attribute :username
    end

    # #TO_H or #CALL
    UserSerializer.(user) # => {username: "serega"}

    # #TO_JSON
    UserSerializer.to_json(user) # => '{"username":"serega"}'

    # #AS_JSON
    UserSerializer.as_json(user) # => {"username" => "serega"}
  ```

  By default all attributes and all nested attributes are serialized.

  We can select needed attributes using modifiers: `with`, `only`, `except`.
  ```ruby
    # User has only `username` attribute
    UserSerializer.(user, except: %i[username]) # => {}
    # same
    UserSerializer.new(except: %i[username]).(user) # => {}
  ```

  Validation of modifiers can be skipped with `check_initiate_params: false` option.
  ```ruby
    UserSerializer.new(only: %i[foo bar]).(user) # => raises Serega::AttributeNotExist, "Attribute 'foo' not exists"
    UserSerializer.new(only: %i[foo bar], check_initiate_params: false).(user) # => {}
  ```

  Serializing Arrays or Enumerable objects.
  ```ruby
    UserSerializer.([user, user]) # => [{username: "serega"}, {username: "serega"}]
  ```

  Serializing with context
  ```ruby
    UserSerializer.attribute(:username) {|obj, ctx| ctx[:username] || obj.username }
    UserSerializer.(user, context: {username: 'janedoe'}) # => {username: "janedoe"}
  ```

  Manually specifying that serializing one or many objects.
  This is useful when serializing `<Struct>`, which is `<Enumerable>`, but still it is a single object.
  Or some custom lists, which have no `<Enumerable>` ancestor.
  ```ruby
    struct_user = Struct.new(:username).new('bot')
    UserSerializer.(struct_user, many: false) # => {username: "bot"}
  ```

  Select nested attributes to serialize
  ```ruby
    PostSerializer.new(only: { user: :username }).(post)
    PostSerializer.new(except: { user: %i[email username] }).(post)
    PostSerializer.new(with: {user: :email}).(post)
  ```

  Select nested attributes with :string_modifiers plugin. It allows to provide params as Strings.
  Its handy to use this plugin with GET requests params.
  ```ruby
    PostSerializer.plugin :string_modifiers
    PostSerializer.new(only: "id,user(id,username)").(post)
    PostSerializer.new(except: "user(username,email)").(post)
    PostSerializer.new(with: "user(email)").(post)
  ```

### How to add attributes
  ```ruby
    class UserSerializer < Serega
      # Regular attribute
      attribute :first_name

      # Option :key specifies method in object
      attribute :FirstName, key: :first_name

      # Option :value specifies attribute value
      attribute :first_name, value: proc { |_obj, _ctx| "foo" }

      # Block also specifies attribute value
      attribute(:first_name) { |_obj, _ctx| "foo" }

      # Option :const specifies attribute with specific constant value
      attribute(:type, const: 'user')

      # Option :hide specifies attributes that should not be serialized by default
      # They can be serialized only when directly requested by modifiers :with or :only
      #
      #    UserSerializer.to_h(users, with: :tags)
      attribute :tags, hide: true

      # Option :delegate
      # With plugin :preload and enabled :auto_preload_attributes_with_delegate option it also preloads delegated resource.
      #
      # Same as:
      #     attribute(:posts_count, preload: :stat) { |user| user.stat.posts_count }
      attribute :posts_count, delegate: { to: :stat }

      # Option :delegate with :allow_nil
      #
      # Same as:
      #     attribute(:address_line_1, key: :line_1, preload: :address) { |user| user.address&.line1 }
      attribute :address_line_1, key: :line_1, delegate: { to: :address, allow_nil: true }

      # Option :serializer specifies nested serializer for attribute
      # We can specify serializer as Class, String or Proc.
      attribute :posts, serializer: PostSerializer
      attribute :posts, serializer: "PostSerializer"
      attribute :posts, serializer: -> { PostSerializer }

      # Option `:many` specifies a has_many relationship
      # Usually it is defined automatically by checking `value.is_a?(Enumerable)`
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

## Configuration

  ```ruby
    class AppSerializer < Serega
      # Configure adapter to serialize to JSON,
      # if Oj gem loaded default is `Oj.dump(data, mode: :compat)` otherwise it is `JSON.dump`
      config.to_json = ->(data) { Oj.dump(data, mode: :compat) }

      # Configure adapter to de-serialize JSON,
      # if Oj gem loaded default is `Oj.load(data)` otherwise it is `JSON.parse`
      config.from_json = ->(data) { Oj.load(data) }

      # Skip/enable validation of modifiers params `with`, `except`, `only`
      # It can be useful to save some small amount of processing time if you know attributes are correct.
      config.check_initiate_params = false # default is true, enabled

      # Store structs with lists of serialized attributes to not recalculate them for each serialization.
      # This can slightly increase performance.
      # We store 1 cached_map per serialization, cached_key is combined
      # `with`, `except`, `only` serialization options.
      # Better do benchmark for your serialization use case.
      config.max_cached_map_per_serializer_count = 50 # default is 0, disabled

      # With context_metadata plugin:
      config.context_metadata.key=(value) # Changes key used to add context_metadata. By default it is :meta

      # With formatters plugin:
      # Add new formatters
      config.formatters.add(key => proc_value)

      # With metadata plugin:
      # We can configure to automatically hide some attributes or automatically add preloads
      config.preloads.auto_preload_attributes_with_delegate = bool # Default is false
      config.preloads.auto_preload_attributes_with_serializer = bool # Default is false
      config.preloads.auto_hide_attributes_with_preload = bool # Default is false

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
  - :loader (required) [Symbol, Proc, callable] - Defines how to fetch values for batch of keys.
  - :default (optional) - Default value used when loader does not return value for current key. By default it is `nil` or `[]` when attribute has additional option `many: true` (`attribute :name, many: true, batch: { ... }`).

  If `:loader` was defined via Symbol then batch loader must be defined using `config.batch_loaders.define(:loader_name) { ... }` method.
  Result of this block must be a Hash with provided keys.

  Batch loader works well with [`activerecord_preloads`][plugin-activerecord_preloads] plugin

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
      # Parameter `points` can be used to find nested attributes that will be serialized
      config.batch_loaders.define(:posts_comments) do |keys, context, points|
        Comment.where(post_id: keys).where(is_spam: false).group_by(&:post_id)
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
