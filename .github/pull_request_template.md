## What this PR does

<!-- One paragraph: what changed and why. -->

## Type of change

- [ ] Bug fix
- [ ] New feature or enhancement
- [ ] Refactor (no behaviour change)
- [ ] Docs / i18n update
- [ ] New Bible translation
- [ ] Test coverage

## Checklist

- [ ] Tests written first (red → green → refactor)
- [ ] Full suite green locally (`bundle exec rspec`)
- [ ] System spec updated in the same commit if any UI surface changed
- [ ] Both `en.yml` and `es.yml` updated for any new user-facing string
- [ ] `bundle exec rubocop` clean
- [ ] `bundle exec erb_lint --lint-all` clean
- [ ] No new Google-hosted dependencies (fonts, CDN links, analytics)
