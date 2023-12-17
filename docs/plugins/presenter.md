
### Plugin :presenter

Helps to write clean code by using a Presenter class.

```ruby
class UserSerializer < Serega
  plugin :presenter

  attribute :name
  attribute :address

  class Presenter
    def name
      [first_name, last_name].compact_blank.join(' ')
    end

    def address
      [country, city, address].join("\n")
    end
  end
end
```
