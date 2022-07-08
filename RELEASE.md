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
6. Update version number in VERSION file
7. Make local gem release `gem build serega.gemspec`
8. Repeat
  ```
  bundle exec rspec \
  && bundle exec rubocop -A \
  && bundle exec rake examples
  ```
8. Commit all changes except VERSION file
9. Add CHANGELOG, README notices.
10. Commit VERSION, CHANGELOG, README.
  ```
  git add . && git commit -m "Release v$(cat "VERSION")"
  ```
11. Add tag `git tag -a v$(cat "VERSION") -m v$(cat "VERSION")`
12. Commit and push changes `git push origin master`
13. Push tags `git push origin --tags`
14. Push gem `gem push serega-$(cat "VERSION").gem`
