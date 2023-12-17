
### Plugin :preloads

Allows to define `:preloads` to attributes and then allows to merge preloads
from serialized attributes and return single associations hash.

Plugin accepts options:

- `auto_preload_attributes_with_delegate` - default `false`
- `auto_preload_attributes_with_serializer` - default `false`
- `auto_hide_attributes_with_preload` - default `false`

These options are extremely useful if you want to forget about finding preloads
manually.

Preloads can be disabled with the `preload: false` attribute option.
Automatically added preloads can be overwritten with the manually specified
`preload: :xxx` option.

For some examples, **please read the comments in the code below**

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

  # `preload: :user_stats` added manually
  attribute :followers_count, preload: :user_stats,
    value: proc { |user| user.user_stats.followers_count }

  # `preload: :user_stats` added automatically, as
  # `auto_preload_attributes_with_delegate` option is true
  attribute :comments_count, delegate: { to: :user_stats }

  # `preload: :albums` added automatically as
  # `auto_preload_attributes_with_serializer` option is true
  attribute :albums, serializer: 'AlbumSerializer'
end

class AlbumSerializer < AppSerializer
  attribute :images_count, delegate: { to: :album_stats }
end

# By default, preloads are empty, as we specify `auto_hide_attributes_with_preload`
# so attributes with preloads will be skipped and nothing will be preloaded
UserSerializer.new.preloads
# => {}

UserSerializer.new(with: :followers_count).preloads
# => {:user_stats=>{}}

UserSerializer.new(with: %i[followers_count comments_count]).preloads
# => {:user_stats=>{}}

UserSerializer.new(
  with: [:followers_count, :comments_count, { albums: :images_count }]
).preloads
# => {:user_stats=>{}, :albums=>{:album_stats=>{}}}
```

---

#### SPECIFIC CASE #1: Serializing the same object in association

For example, you show your current user as "user" and use the same user object
to serialize "user_stats". `UserStatSerializer` relies on user fields and any
other user associations. You should specify `preload: nil` to preload
`UserStatSerializer` nested associations to the "user" object.

```ruby
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_delegate: true,
    auto_preload_attributes_with_serializer: true,
    auto_hide_attributes_with_preload: true
end

class UserSerializer < AppSerializer
  attribute :username
  attribute :user_stats,
    serializer: 'UserStatSerializer',
    value: proc { |user| user },
    preload: nil
end
```

#### SPECIFIC CASE #2: Serializing multiple associations as a single relation

For example, "user" has two relations - "new_profile" and "old_profile". Also
profiles have the "avatar" association. And you decided to serialize profiles in
one array. You can specify `preload_path: [[:new_profile], [:old_profile]]` to
achieve this:

```ruby
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_delegate: true,
    auto_preload_attributes_with_serializer: true
end

class UserSerializer < AppSerializer
  attribute :username
  attribute :profiles,
    serializer: 'ProfileSerializer',
    value: proc { |user| [user.new_profile, user.old_profile] },
    preload: [:new_profile, :old_profile],
    preload_path: [[:new_profile], [:old_profile]] # <--- like here
end

class ProfileSerializer < AppSerializer
  attribute :avatar, serializer: 'AvatarSerializer'
end

class AvatarSerializer < AppSerializer
end

UserSerializer.new.preloads
# => {:new_profile=>{:avatar=>{}}, :old_profile=>{:avatar=>{}}}
```

#### SPECIFIC CASE #3: Preload association through another association

```ruby
attribute :image,
  preload: { attachment: :blob }, # <--------- like this one
  value: proc { |record| record.attachment },
  serializer: ImageSerializer,
  preload_path: [:attachment] # or preload_path: [:attachment, :blob]
```

In this case, we don't know if preloads defined in ImageSerializer, should be
preloaded to `attachment` or `blob`, so please specify `preload_path` manually.
You can specify `preload_path: nil` if you are sure that there are no preloads
inside ImageSerializer.

---

📌 Plugin `:preloads` only allows to group preloads together in single Hash, but
they should be preloaded manually.

There are only [activerecord_preloads][activerecord_preloads] plugin that can
be used to preload these associations automatically.
