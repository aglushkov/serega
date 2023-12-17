# Plugin :root

Allows to add root key to your serialized data

Accepts options:

- :root - specifies root for all responses
- :root_one - specifies the root key for single object serialization only
- :root_many - specifies the root key for multiple objects serialization only

Adds additional config options:

- config.root.one
- config.root.many
- config.root.one=
- config.root_many=

The default root is `:data`.

The root key can be changed per serialization.

```ruby
 # @example Change root per serialization:

 class UserSerializer < Serega
   plugin :root
 end

 UserSerializer.to_h(nil)              # => {:data=>nil}
 UserSerializer.to_h(nil, root: :user) # => {:user=>nil}
 UserSerializer.to_h(nil, root: nil)   # => nil
```

The root key can be removed for all responses by providing the `root: nil`
plugin option.

In this case, no root key will be added. But it still can be added manually.

```ruby
 #@example Define :root plugin with different options

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
   plugin :root, root: nil # no root key by default
 end
```
