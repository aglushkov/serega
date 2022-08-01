# Release process

1. Run
  ```
  bundle update \
  && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update
  ```

2. Run
  ```
  bundle exec rspec \
  && bundle exec rubocop -A \
  && bundle exec rake examples
  ```

3. Commit changes

4. Update version number in VERSION file

5. Checkout to new release branch
  ```
  git co -b "v$(cat "VERSION")"
  ```

6. Make local gem release
  ```
  gem build serega.gemspec
  ```

7. Repeat
  ```
  bundle update \
    && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
    && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update \
    && bundle exec rspec \
    && bundle exec rubocop -A \
    && bundle exec rake examples
  ```

8. Add CHANGELOG, README notices.

9. Commit all changes.
  ```
  git add . && git commit -m "Release v$(cat "VERSION")"
  git push origin "v$(cat "VERSION")"
  ```

10. Merge PR when all checks pass.

11. Add tag
  ```
  git checkout master
  git pull --rebase origin master
  git tag -a v$(cat "VERSION") -m v$(cat "VERSION")
  git push origin master
  git push origin --tags
  ```

12. Push new gem version
  ```
  gem push serega-$(cat "VERSION").gem
  ```
