[![Gem Version](https://badge.fury.io/rb/serega.svg)](https://badge.fury.io/rb/serega)
[![GitHub Actions](https://github.com/aglushkov/serega/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/serega/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/test_coverage)](https://codeclimate.com/github/aglushkov/serega/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f10c0659e16e25e49faa/maintainability)](https://codeclimate.com/github/aglushkov/serega/maintainability)

# Serega Ruby Serializer

  The Serega Ruby Serializer provides easy and powerfull DSL to describe your objects and to serialize them to Hash or JSON.

  It has also some great features:
  
    * Configurable serialized fields. No more multiple serializers for same resource. Yay!
    * Built-in object presenter ([presenter] plugin)
    * Solution for N+1 problem (via [preloads] or [activerecord_preloads] plugins)
    * Custom metadata (via [metadata] or [context_metadata] plugins)
    * Custom attribute formatters ([formatters] plugin)

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

      relation :user, serializer: UserSerializer
    end
```

### How to serialize
  ```ruby
    # Example:
    UserSerializer.to_h(user)         # single object
    UserSerializer.to_h([user, user]) # Array or some Enumerable object

    # Serialize with context:
    UserSerializer.to_h(user, context: { current_user: current_user })

    # Select attributes to serialize
    UserSerializer.new(only: %i[id username]).to_h(user)
    UserSerializer.new(except: %i[email username]).to_h(user)
    UserSerializer.new(with: %i[email]).to_h(user)

    # Select nested attributes to serialize
    PostSerializer.new(only: { user: :username }).to_h(post)
    PostSerializer.new(except: { user: %i[email username] }).to_h(post)
    PostSerializer.new(with: {user: :email}).to_h(post)

    # Select with :string_modifiers plugin
    # Simplifies selecting attributes when modifiers are params of GET requests
    PostSerializer.plugin :string_modifiers
    PostSerializer.new(only: "id,user(id,username)").to_h(post)
    PostSerializer.new(except: "user(username,email)").to_h(post)
    PostSerializer.new(with: "user(email)").to_h(post)

    # Serialize to JSON string
    # Configure adapter to serialize to JSON, default is JSON.dump
    AppSerializer.config[:to_json] = ->(data) { Oj.dump(data, mode: :compat) }
    UserSerializer.to_json(user)

    # Serialize as JSON - keys becomes strings, values will be serialized as in JSON.
    # For example, this can be useful to use result as sidekiq argument.
    UserSerializer.as_json(user)
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
      attribute :tags, hide: true

      # Option :serializer specifies nested serializer for attribute
      # We can specify serializer as Class, String or Proc.
      attribute :posts, serializer: PostSerializer
      attribute :posts, serializer: "PostSerializer"
      attribute :posts, serializer: -> { PostSerializer }

      # We can use `relation` word to describe attributes with serializers
      relation :posts, serializer: PostSerializer

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
      config[:formatters][:iso_time] = ->(time) { time.iso8601.round(6) }
      attribute :created_at, format: :iso_time
      attribute :updated_at, format: :iso_time

      # Option `:format` also can be used as Proc
      attribute :created_at, format: proc { |time| time.strftime("%Y-%m-%d")}
    end
  ```

## Plugins

### Plugin :preloads
  Allows to find `preloads` for current serializer. It merges **only** preloads specified in currently serialized attributes, skipping preloads of not serialized attributes.

  Preloads can be fetched using `MySerializer.preloads` or `MySerializer.new(modifiers_opts).preloads` methods.

  Config option `config[:preloads][:auto_preload_attributes_with_serializer] = true` can be specified to automatically add `preload: <attribute_key>` to all attributes with `:serializer` option.

  Config option `config[:preloads][:auto_hide_attributes_with_preload] = true` can be specified to automatically add `hide: true` to all attributes with any `:preload`. It also works for automatically assigned preloads.

  Preloads can be disabled with `preload: false` option. Or auto added preloads can be overwritten with `preload: <another_key>` option.

  ```ruby
    class AppSerializer < Serega
      plugin :preloads,
        auto_preload_attributes_with_serializer: true,
        auto_hide_attributes_with_preload: true
    end

    class PostSerializer < AppSerializer
      attribute :views_count, preload: :views_stats, value: proc { |post| post.views_stats.views_count  }
      attribute :user, serializer: 'UserSerializer'
    end

    class UserSerializer  < AppSerializer
      attribute :followers_count, preload: :user_stats, value: proc { |user| user.user_stats.followers_count  }
    end

    PostSerializer.preloads # => {:views_stats=>{}, :user=>{:user_stats=>{}}}
  ```

### Plugin :activerecord_preloads

  Automatically preloads everything specified in `:preload` attributes options to serialized object during
  serialization

  ```ruby
    class AppSerializer < Serega
      plugin :activerecord_preloads # also adds :preloads plugin automatically
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
    plugin :formatters

    config[:formatters][:iso8601] = ->(value) { time.iso8601.round(6) }
    config[:formatters][:on_off] = ->(value) { value ? 'ON' : 'OFF' }
    config[:formatters][:money] = ->(value) { value.round(2) }

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

### Plugin :validate_modifiers

  By default we will not raise any error if not existed attribute provided in modifiers (`:only, :except, :with` options provided to `Serializer#new` method).

  We can enable this validation using `:validate_modifiers` plugin

  ```ruby
    UserSerializer.plugin(:validate_modifiers)
    UserSerializer.new(only: [:foo, :bar]) # => raises Serega::AttributeNotExist
  ```

  Now we will raise `Serega::AttributeNotExist` error when not existing attribute provided to modifiers.


### Plugin :hide_nil

  Allows to hide attributes which values are nil

  ```ruby
    class UserSerializer < Serega
      plugin :hide_nil

      attribute :email, hide_nil: true
    end
  ```

## Errors

  - `Serega::Error` is a base error raised by this gem.
  - `Serega::AttributeNotExist` error is raised when validating attributes in `:only, :except, :with` modifiers with `:validate_modifiers` plugin

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `VERSION` file, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aglushkov/serega.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
