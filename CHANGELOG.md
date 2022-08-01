## [Unreleased]

- Add config option for `:preload` plugin  - `:auto_preload_attributes_with_delegate`.
  ```ruby
    # Setup:
    class Serega
      plugin :preload, auto_preload_attributes_with_delegate: true
      # or
      plugin :preload
      config[:preload][:auto_preload_attributes_with_delegate] = true
    end
  ```

- Add option :delegate when defining attributes.
  Examples:
  ```ruby
    attribute :comments_count, delegate: { to: :user_stat }
    attribute :address_line_1, key: :line_1, delegate: { to: :address, allow_nil: true }
  ```

- Prohibit to use option :preload together with option :const (#23)

- Rename constants. Add prefix Serega for come classes. Previously in applications that use same class names this classes have to be defined with two colons "::".
  - Serega::Attribute -> Serega::SeregaAttribute
  - Serega::Convert -> Serega::SeregaConvert
  - Serega::ConvertItem -> Serega::SeregaConvertItem
  - Serega::Error -> Serega::SeregaError
  - Serega::Helpers -> Serega::SeregaHelpers
  - Serega::Map -> Serega::SeregaMap
  - Serega::Utils -> Serega::SeregaUtils
  - Serega::Validations -> Serega::SeregaValidations


## [0.1.5] - 2022-08-27

- Added config option `config[:preloads][:auto_hide_attributes_with_preload]` to `preloads` plugin. By default it is `false`.

- Plugin `validate_modifiers` now raises `Serega:AttributeNotExist` error when requested attribute not exists

- Change `preloads` plugin config option `config[:preloads][:auto_preload_relation] = true` to `config[:preloads][:auto_preload_attributes_with_serializer] = false`, so now there are no surprises where this preloads come from.

## [0.1.4] - 2022-08-25

- Fix context_metadata plugin error
  ```ruby
    wrong number of arguments (given 2, expected 1)
  ```

## [0.1.3] - 2022-08-25

- Fix activerecord_preloads plugin error
  ```ruby
    wrong number of arguments (given 2, expected 1)
  ```

## [0.1.2] - 2022-08-24

- Added :const attribute option to specify attribute with constant value

- Added `.call` and `#call` methods same as `.to_h` and `#to_h`. New methods were added as when we can serialize list of objects the result will be array, so `to_h` is a bit confusing

## [0.1.1] - 2022-08-13

- Fix validation and README docs about attribute option `:key`. Previously we validate option :method instead

## [0.1.0] - 2022-08-07

- Initial public release ([@aglushkov][])


[@aglushkov]: https://github.com/aglushkov
