### Plugin :string_modifiers

Allows to specify modifiers as strings.

Serialized attributes must be split with `,` and nested attributes must be
defined inside brackets `()`.

Modifiers can still be provided the old way using nested hashes or arrays.

```ruby
PostSerializer.plugin :string_modifiers
PostSerializer.new(only: "id,user(id,username)").to_h(post)
PostSerializer.new(except: "user(username,email)").to_h(post)
PostSerializer.new(with: "user(email)").to_h(post)

# Modifiers can still be provided the old way using nested hashes or arrays.
PostSerializer.new(with: {user: %i[email, username]}).to_h(post)
```
