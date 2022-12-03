# Release process

1. Run and fix all warnings
  ```
  bundle update \
    && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update \
    && bundle exec rspec \
    && bundle exec rubocop -A \
    && bundle exec rake examples
  ```

2. Update version number in VERSION file

3. Checkout to new release branch
  ```
  git co -b "v$(cat "VERSION")"
  ```

4. Make local gem release
  ```
  gem build serega.gemspec
  ```

5. Repeat
  ```
  bundle update \
    && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update \
    && bundle exec rspec \
    && bundle exec rubocop -A \
    && bundle exec rake examples
  ```

6. Add CHANGELOG, README notices.

7. Commit all changes.
  ```
  git add . && git commit -m "Release v$(cat "VERSION")"
  git push origin "v$(cat "VERSION")"
  ```

8. Merge PR when all checks pass.

9. Add tag
  ```
  git checkout master
  git pull --rebase origin master
  git tag -a v$(cat "VERSION") -m v$(cat "VERSION")
  git push origin master
  git push origin --tags
  ```

10. Push new gem version
  ```
  gem push serega-$(cat "VERSION").gem
  ```
