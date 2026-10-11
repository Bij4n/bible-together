# Bible Together

A Ruby on Rails app for reading, highlighting, annotating, and sharing the
Bible — privately, with friends, in Bible-study groups, or publicly — built
around the words of Jesus. Live at
[bible-together.org](https://bible-together.org). Bilingual UI (English +
Spanish) with KJV and Reina-Valera 1909 text, character-level highlights,
rich-text notes, keyword and semantic search, and a reading-first design
(Source Serif 4 for scripture, Inter for chrome, Medium green accent on a
white ground).

## Features

**Reading**
- Two public-domain translations: King James Version (KJV) and
  Reina-Valera 1909 (RV1909). Translation picker preserves book and chapter
  across switches.
- Red-letter Jesus words from character-offset ranges at import time, with a
  handful of source slips corrected from `config/red_letter/kjv.yml`. RV1909
  has the same red verses as the KJV: fully red verses are mirrored, and
  verses where he speaks for part of the verse come from a reviewed file,
  `config/red_letter/rv1909.yml`.
- Reader layers (signed in): your highlights, a group's shared layer, or the
  community layer — one lens at a time via the layer switcher.
- Anonymous visitors read the community layer at `/bible/...` (public notes,
  dotted underlines, no personal toolbar).

**Highlighted in Red** ([`/red`](https://bible-together.org/red))
- A reading mode built on the red-letter text: narration dimmed, his words in
  red, and a "His words only" toggle. Steps only through chapters where he
  speaks.
- Curated passages, each with every gospel that tells it: 40 parables, 9 word
  pictures from John, 31 encounters (what he did) and 20 sayings. An
  encounter's page shows the story at full strength.
- Eight themes that set what he did beside what he said.
- All of the red text is there, hard sayings included, and the site adds no
  commentary of its own.
- The lists live in `config/passages.yml` and `config/themes.yml`; edit them
  and deploy, with no data step.

**Annotation**
- Character-level highlights in four muted colors. OSIS-ref anchoring survives
  schema changes and maps across translations at the verse level.
- Action Text notes on one or more highlights.
- Per-note visibility: only you, friends (mutual follows), specific people,
  a group, or public.
- Threaded comments on any note you can see.

**Social**
- Follow authors; share notes with friends without picking names each time.
- Group Bibles with real-time broadcast via Action Cable — shared notes and
  comments appear live for others on the same chapter.
- Join groups via invitation code or email link (token survives sign-up).
- A study chooses what it reads: the whole Bible, Highlighted in Red chapter
  by chapter, or a list or theme one passage at a time with a "We are here"
  marker a manager moves. A reader can make Highlighted in Red what Read
  opens, in settings.

**Community**
- [`/community`](https://bible-together.org/community) — global feed of public
  notes (Recent / Top, book filter, pagination).
- Community reading layer on any chapter (`/bible/kjv/john/3` when signed out,
  or `?layer=community` when signed in). Legacy `/public/bible/...` URLs
  301-redirect here.
- Homepage hero + community section surface featured and recent public notes.
- Upvoting, flagging, admin moderation (feature/hide, resolve flags).

**Search**
- Keyword search over verse text and visible note bodies via `pg_search`
  (`ts_headline` wrapping).
- Semantic search via a local Python embedding service
  (`sentence-transformers/all-MiniLM-L6-v2`); falls back to keyword when
  the service is down.
- Scope: verses / notes / both; current translation or all installed
  translations.
- "Search only the words of Jesus": keyword search then matches inside the
  red text alone.

**Accessibility**
- WCAG 2.1 AA checked on major surfaces (`axe-core-rspec`).
- Accent-green `:focus-visible` rings; `prefers-reduced-motion` honored
  globally.
- Light theme only; dark mode was removed in June 2026.
- Print stylesheet for chapter output.

## Stack

- **Ruby** 3.4.9 / **Rails** 8.1.3 / **PostgreSQL** 16
- **Hotwire** (Turbo + Stimulus) + **Tailwind CSS v4**
- **Import maps** — no webpack/esbuild
- **Action Text**, **Action Cable**, **Solid Queue**, **Solid Cache**
- **Devise** + **devise-i18n**
- **Python** embedding service (FastAPI + uvicorn) — optional locally
- **Testing**: RSpec, FactoryBot, Capybara, headless **Firefox** + geckodriver,
  axe-core-rspec

Design tokens and typography live in [`DESIGN.md`](DESIGN.md). Redesign
history and remaining sprints: [`REDESIGN.md`](REDESIGN.md).

## Getting started

Requirements: Ruby 3.4.9 (asdf recommended), PostgreSQL 16+, Python 3.11+ only
if you want semantic search.

```bash
git clone git@github.com:Bij4n/bible-together.git
cd bible-together
bin/setup                          # gems, db:create, db:schema:load
bin/rails bible:import[kjv]        # ~30s
bin/rails bible:import[rv1909]     # ~10s; red-letter from KJV + config/red_letter
bin/dev                            # web + Tailwind + embedding service
```

Open [http://localhost:3000](http://localhost:3000). Read scripture at
`/bible/kjv/gen/1` (community layer when signed out). Sign up to highlight
and leave notes.

Skip the embedding service if you don't need Concept search:

```bash
EMBEDDING_SERVICE_SKIP=1 bin/dev
```

Generate embeddings (one-time, CPU-heavy):

```bash
bin/rails embeddings:generate
```

Dev database name: `bible_together_development` (see `config/database.yml`).

## Development

```bash
bundle exec rspec                  # full suite (~900 examples)
bundle exec rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman
```

Single file:

```bash
bundle exec rspec spec/requests/community_spec.rb
```

Browser automation uses **Firefox only** — not Chrome/Chromium (project rule).

## Bible content and provenance

Public domain, SHA-pinned, documented in `config/bible_sources.yml`:

- **KJV** — [seven1m/open-bibles](https://github.com/seven1m/open-bibles)
  (`eng-kjv.osis.xml`), USFX → OSIS via Haiola.
- **RV1909** — [gratis-bible/bible](https://github.com/gratis-bible/bible)
  (`es/sparv.xml`). Text markers identify the 1909 edition (not copyrighted
  RVR1960).

The OSIS importer handles milestone-style (Haiola) and container-style
(ZefToOsis) OSIS 2.1.1 dialects.

## Architecture

- **Models** — `Verse`, `Highlight`, `Note`, `Comment`, `Group`, `Follow`, etc.
- **Services** — `app/services/` (`Bible::OsisImporter`, `SearchService`,
  `SemanticSearchService`, `OsisRef`, …)
- **Concerns** — e.g. `CommunityChapterLoading` for the community reader layer
- **Stimulus** — `app/javascript/controllers/`, one concern per file
- **Embeddings** — `services/embedding-service/`, started via `bin/embedding`

Roadmap and decision log: [`PLAN.md`](PLAN.md). Contributor workflow:
[`CONTRIBUTING.md`](CONTRIBUTING.md) (TDD, bilingual copy, system specs with UI
changes).

## Contributing

PRs welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first — tests before code,
system specs ship with UI changes, update both `en.yml` and `es.yml`, self-host
all assets (no Google Fonts/CDN).

Questions: [GitHub Discussions](https://github.com/Bij4n/bible-together/discussions).
Bugs and tasks: [Issues](https://github.com/Bij4n/bible-together/issues).

## License

MIT. See [`LICENSE`](LICENSE).
