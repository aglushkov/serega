# Release process

1. Check documentation
```
yard --no-cache --quiet && yard stats --list-undoc
```

2. Run and fix all warnings
```
bundle update \
  && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update \
  && bundle exec rspec \
  && bundle exec rubocop -A \
  && bundle exec rake examples
```

3. Update version number in VERSION file

4. Checkout to new release branch
```
git co -b "v$(cat "VERSION")"
```

5. Make local gem release
```
gem build serega.gemspec
```

6. Repeat
```
bundle update \
  && BUNDLE_GEMFILE=gemfiles/5.2.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/6.1.gemfile bundle update \
  && BUNDLE_GEMFILE=gemfiles/7.0.gemfile bundle update \
  && bundle exec rspec \
  && bundle exec rubocop -A \
  && bundle exec rake examples
```

7. Add CHANGELOG, README notices.

8. Commit all changes.
```
git add . && git commit -m "Release v$(cat "VERSION")"
git push origin "v$(cat "VERSION")"
```

9. Merge PR when all checks pass.

10. Add tag
```
git checkout master
git pull --rebase origin master
git tag -a v$(cat "VERSION") -m v$(cat "VERSION")
git push origin master
git push origin --tags
```

11. Push new gem version
```
gem push serega-$(cat "VERSION").gem
```
