# Plugin :activerecord_preloads

Automatically preloads associations to serialized objects.

Depends on the [preloads][preloads.md] plugin, that must be loaded first

It takes all defined preloads from serialized attributes (including attributes
from serialized relations), merges them into a single associations hash, and then
uses ActiveRecord::Associations::Preloader to preload associations to objects.

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
  attribute :downloads_count, preload: :downloads,
    value: proc { |album| album.downloads.count }
end

UserSerializer.to_h(user)
# => preloads {users_stats: {}, albums: { downloads: {} }}
```
Automatically preloads associations to serialized objects.

It takes all defined preloads from serialized attributes (including attributes
from serialized relations), merges them into a single associations hash, and then
uses ActiveRecord::Associations::Preloader to preload associations to objects.

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
  attribute :downloads_count, preload: :downloads,
    value: proc { |album| album.downloads.count }
end

UserSerializer.to_h(user)
# => preloads {users_stats: {}, albums: { downloads: {} }}
```
