# Contributing to Open Bible

Thanks for wanting to help. Open Bible is a Rails app for reading, marking up,
and sharing scripture — built around the belief that scripture is meant to be
read with someone. Contributions are welcome whether you're fixing a bug, adding
a new public-domain translation, improving accessibility, or tightening the
bilingual coverage.

---

## What we're looking for

- **Bug fixes** — anything in the issues list, or something you noticed while
  using the app.
- **New public-domain Bible translations** — the OSIS importer handles both
  major dialect variants. See [Adding a translation](#adding-a-translation).
- **Accessibility improvements** — WCAG 2.1 AA is the floor, not the ceiling.
- **i18n coverage** — English and Spanish are both required in every PR. If
  you're fluent in another language and want to discuss adding a third UI locale,
  open an issue first.
- **Test coverage** — additional system specs, edge-case model specs, or request
  specs for underspecified flows.
- **Documentation** — if something in the README or code is unclear, fix it.

## What to skip (for now)

- Large new features — open an issue and discuss before building. The roadmap
  lives in `PLAN.md` and there's usually context behind why something isn't
  built yet.
- Abstractions for their own sake. Three similar lines of code is better than a
  premature helper.
- Phone numbers, SMS, or phone fields anywhere — firm product decision, not
  negotiable.
- Copyrighted Bible translations. If you're unsure whether a text is public
  domain, open an issue and ask before building.

---

## Getting set up

See [Getting started](README.md#getting-started) in the README.

**Requirements:** Ruby 3.4.9 (via asdf or similar), PostgreSQL 16+, Python 3.11+
(only for semantic search — skippable with `EMBEDDING_SERVICE_SKIP=1`).

```bash
bin/setup                          # install gems, prepare dev + test DBs
bin/rails bible:import[kjv]        # ~30s, downloads + imports KJV
bin/rails bible:import[rv1909]     # ~10s, imports RV1909
EMBEDDING_SERVICE_SKIP=1 bin/dev   # start the server without Python
```

---

## Development rules

These exist for specific reasons and are enforced by CI. They're not negotiable
for merging.

### Tests first — always

Every change follows red → green → refactor:

1. Write a failing test that describes the behaviour.
2. Run it. Confirm it fails for the right reason — not a typo, not a missing
   file, but because the feature doesn't exist yet.
3. Write the minimum code to make it pass.
4. Run the full suite (`bundle exec rspec`), not just the one file.
5. Refactor with the test as a safety net.
6. Run the full suite again.

No "I'll add tests after." PRs without tests for new behaviour won't be merged.

### System specs ship with UI changes

If your PR touches a view, layout, Stimulus controller, or anything a user
interacts with, it must update the system spec that exercises that surface —
in the **same commit**. Moving a button and leaving its spec asserting the
old location is a CI failure.

System specs run under `rack_test` by default. Tag `js: true` only when the
example needs Stimulus, Turbo, Trix, or anything JavaScript-driven. Without
the tag, clicks on Stimulus targets will silently do nothing.

### Firefox only — no Chrome

Browser automation uses **Firefox + geckodriver**. Not Chrome, Chromium, or
chromedriver. The driver setup is in `spec/rails_helper.rb`. If your Firefox
is in a non-standard location, set `FIREFOX_BINARY` and `GECKODRIVER_PATH`
environment variables before running the suite.

### No Google-hosted dependencies

Fonts, analytics, tag managers — none. All fonts (Inter, Instrument Serif,
JetBrains Mono) are self-hosted OFL `.woff2` files in `public/fonts/`. If
you need a font or icon, download it and commit it. No CDN links, no
`fonts.googleapis.com`, no Google Analytics.

### Bilingual — English and Spanish in the same PR

Every user-facing string must appear in both `config/locales/en.yml` and
`config/locales/es.yml` in the same PR. A missing translation won't ship.

I18n keys mirror the view path: `app.bible.reader.chapter_heading` for
`app/views/bible/reader/chapter.html.erb`.

If you're not fluent in Spanish, flag it in the PR description so a
Spanish speaker can verify the wording.

### Commit style

- Short imperative subject line, 50 characters or fewer.
- Blank line, then optional body wrapped at 72 characters.
- No emoji.
- Conventional Commits prefixes (`feat:`, `fix:`, `docs:`, `chore:`,
  `refactor:`, `test:`) are fine but not required.

Good: `add verse offset validator` · `fix n+1 on highlights index`

Not: `feat: ✨ implement comprehensive thing 🔐` · `Update files` · `fix stuff`

### No AI tool attribution

Please don't attribute AI assistance anywhere in the repository — not in commit
messages, code comments, PR descriptions, or anywhere else. Write commit
messages and comments as you would any other contribution.

### One commit per logical change

Avoid bundling unrelated changes. If a commit touches more than ~150 lines
across unrelated files, split it. Focused commits make review faster and
history more useful.

---

## Adding a translation

The OSIS importer handles both major OSIS 2.1.1 dialect variants:
milestone-style (used by seven1m/Haiola, as with the KJV source) and
container-style (used by ZefToOsis, as with the RV1909 source).

To add a new public-domain translation:

1. **Find a public-domain OSIS source.** Confirm the text is genuinely public
   domain. Use text-level markers (distinctive spellings, verse wording) to
   confirm the edition — the RV1909 identification process in `PLAN.md` is a
   worked example of this.

2. **Add an entry to `config/bible_sources.yml`** with `sha256:` pinned to the
   file you verified. Document how you identified the edition in a comment.

3. **Run the importer:**
   ```bash
   bin/rails bible:import[your_code]
   ```
   Read the output for skipped books or parse warnings. The importer logs any
   book whose OSIS code isn't in `config/books.yml`.

4. **Add the translation name to both locales** (`en.yml` and `es.yml`).

5. **Write a spec** in `spec/models/` or `spec/services/` verifying a handful
   of expected verses parsed correctly — check a verse from Genesis, Psalms,
   and a New Testament book at minimum.

6. **Open a PR** with the `bible_sources.yml` entry, the import output
   (paste the summary), and the spec.

---

## Checks CI runs

All six must pass before a PR can merge:

```bash
bundle exec rspec                  # full test suite
bundle exec rubocop -f github      # Ruby style (rubocop-rails-omakase)
bundle exec erb_lint --lint-all    # ERB templates
bundle exec brakeman --no-pager    # security static analysis
bin/bundler-audit                  # gem vulnerability check
bin/importmap audit                # JS dependency check
```

---

## PR checklist

Before opening a pull request:

- [ ] Tests written first (red → green → refactor)
- [ ] Full suite green locally (`bundle exec rspec`)
- [ ] System spec updated in the same commit if any UI surface changed
- [ ] Both `en.yml` and `es.yml` updated for any new user-facing string
- [ ] `bundle exec rubocop` clean
- [ ] `bundle exec erb_lint --lint-all` clean
- [ ] No new Google-hosted dependencies

---

## Code of conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Questions

Use [GitHub Discussions](https://github.com/Bij4n/open-bible/discussions):

- **Q&A** — setup help, "how do I self-host this?", anything that's a
  question with an answer. Threads get marked resolved so others can find them.
- **Ideas** — feature proposals, translation requests, UX suggestions. Open
  here before building something large.
- **General** — introductions, show and tell, anything else.

Save issues for confirmed bugs and actionable tasks. If you're unsure whether
something is a bug or a question, start a Discussion — it can always be
converted to an issue later.
