# HANDOFF.md

> Read this first when picking up the project in a fresh Claude session.
> Goal: orient in under 60 seconds, then go to the right doc for depth.

---

## Where things are right now

- **Production:** [bible-together.org](https://bible-together.org), live since 2026-04-21, on Render. `main` auto-deploys.
- **Repo:** Public on GitHub as [Bij4n/bible-together](https://github.com/Bij4n/bible-together) (MIT). Local checkout: `~/projects/bible-together`.
- **Branch:** `main` — all work through PR #153 merged and live (2026-06-17).
- **Design source of truth:** `DESIGN.md` (v3). Rationale + sprint breakdown: `REDESIGN.md` (R1–R9 shipped on `main`).

### Shipped recently (2026-06-16 → 2026-06-17)

**Platform features (Sprints 1–6, PRs #139–#144):**
- About non-profit copy; UI polish foundation
- Reader book picker with Old/New Testament filter; Jesus words in red
- Group administrators (`admin` role on memberships, owner/manager permissions)
- Usernames + vanity profiles at `/@username`; follow/unfollow; bio on profiles
- Settings expansion (bio, notification preferences)
- Public forum (`/forum` — threads + posts, anyone signed in can participate)

**Landing + chrome (Sprints A–D, PRs #145–#148):**
- Full-bleed hero gradient (no horizontal overflow at 375px); responsive donate CTA copy
- Global vertical rhythm (`py-10 sm:py-12 lg:py-16` on `<main>`)
- Nav IA: **Study** and **Explore** dropdown menus, items ordered by most-used first; two-column footer (Product / Support)
- Platform-wide mobile overflow audit (`spec/system/mobile_overflow_audit_spec.rb`)

**Content + reader (PRs #149–#152):**
- About page rewritten — editorial typographic layout, vision ends on "Jesus.", non-profit + translations in a two-column footer section; reflective blockquote copy removed
- How it works, Contact, Donate pages redesigned to match the About editorial style (thin rules, no card chrome)
- Reader cleanup: verse-per-block is the **only** layout (`reader_prefs` controller deleted); book/chapter/translation controls consolidated into one row

**UI polish pass (PR #153):**
- Auth pages: value-prop subheads under headings
- Settings: six stacked cards → divided editorial sections
- Group show page: clearer hierarchy (members/invite/code consolidated; leave/delete at bottom)
- Search: card chrome removed from form and empty state
- Notes index + dashboard: editorial heading scale + one-line description

**Also closed this cluster:**
- Dark mode **fully removed** — no `data-theme`, no `theme_controller.js`, zero `dark:` classes in views
- Invitation email bug fixed (group invites deliver via `GroupInvitationMailer`)
- Navbar/footer/hero redesign live (dropdown nav + mobile tab bar)

- **GitHub Discussions:** Live. Welcome post pinned as discussion #92 in Announcements.

---

## What to read next, in order

1. **`CLAUDE.md`** — workflow rules (especially Rule 7 no-Chrome / Rule 8 no-Google-fonts / Rule 9 every-UI-commit-ships-its-spec), TDD discipline, commit style, confidence flagging.
2. **`PLAN.md` "Current sprint"** (top of file) — one-paragraph statement of where we are and what's queued. Keep this current as the project moves.
3. **`PLAN.md` decisions log** — the most recent ~5 entries are append-only context for *why* the current code is what it is. Grep here when something looks wrong before assuming it's wrong.
4. **`PROJECT_OVERVIEW.md`** — depth reference (stack, file tour, sprint history). Slower to read; only when you actually need it.

---

## Open questions / where the user needs to weigh in

These are the things sitting on the user's desk, not Claude's. Don't pick them blind.

- **Legal pages** — `/terms`, `/privacy`, `/acceptable-use`. Sprint 15 blocker, still open. More pressing now that the repo is public and the app is accepting donations. Needs jurisdiction decision + drafted copy from the owner before any code can be written.
- **Groups / studies deep-dive** — owner wants a full pass on how groups work: highlighting, notes, sharing, settings, and administrator workflows. Audit for gaps before building more on top.
- **Language-switcher placement** — the account menu still carries locale + auth. Two options exist; owner picks. Audit detail saved at `~/.claude/plans/what-do-you-need-enumerated-ember.md`.
- **Pencil-bridge polish** (Sprint 16.5 PR E) — transition between toolbar dismiss and note-panel reveal. No UX spec locked: slide animation? auto-focus scroll? back-arrow to reopen toolbar? Owner decides the gesture before building.
- **Donation rotation UX redesign** — current behavior forces a rotation on every "Add address." Backlogged design call: `Add` creates inactive, separate `Activate` action promotes. Low urgency; current behaviour works.
- **Issue triage process** — now that the repo is public, how fast and by what criteria does the owner respond to incoming GitHub issues? No tooling needed; just a mental model to have.

---

## Next session queue

**Owner input needed first:**
- **Groups / studies audit** — walk through highlighting, notes, visibility, group admin permissions, and settings. Confirm nothing is missing before new social features.
- **Legal pages** — jurisdiction + copy from owner; then wire `/terms`, `/privacy`, `/acceptable-use`.
- **Language-switcher placement** — once decided, this is a focused Stimulus + CSS change. No code until the owner picks an option.
- **Pencil-bridge polish** — same; the build is straightforward once the UX is specified.

**Autonomous-doable (no owner input needed):**
- **`id="join"` anchor on `/studies`** — nav "Join with code" links to `groups_path(anchor: "join")` but the studies index has no matching anchor. Small fix.
- **Swipe-to-dismiss bottom sheet** — the mobile highlight toolbar (PR #50) and account menu have no swipe gesture. Substantive Stimulus + gesture work; roughly a full sprint segment.
- **Multilingual semantic search (4-step sequenced)** — see `PROJECT_OVERVIEW.md` §8 for the full plan. Currently Concept search is English-only and labeled as such; multilingual covers RV1909. Steps: (1) make `embeddings.rake` translation-agnostic, (2) swap to multilingual model, (3) regenerate embeddings, (4) drop the "(English)" parenthetical from homepage.
- **`/help` or FAQ** — usage guide. No clear demand yet; easy to add.
- **Profile social layer polish** — liking and commenting on notes from profile pages; verify end-to-end UX now that profiles + forum exist.
- **Remaining editorial surfaces** — forum thread show, notes show, admin pages, and Devise mailer HTML still carry pre-redesign card chrome. Low priority; apply the About-page editorial language when touched.

---

## Default operating mode

The user runs sessions in **auto mode** when they want continuous shipping. In auto mode:

- Pick from the autonomous-doable queue, ship one PR per logical change.
- Open the PR, watch CI via the `Monitor` tool, merge when all 5 required checks pass (`test`, `lint`, `scan_ruby`, `scan_js`, GitGuardian). The user has standing instructions to merge yourself when CI is green.
- After each merge, fast-forward local `main` (`git checkout main && git pull`). Note the active feature branch will be deleted by `--delete-branch` on merge.
- Update `PLAN.md` decisions log at the close of any cluster of 3+ related PRs. Don't update for a single PR.
- Don't bundle PRs. Each focused. If you're about to commit 200 lines across unrelated files, stop and split.
- No AI attribution anywhere — not in commits, PRs, code, docs, comments, anywhere. Ever.

When the user provides explicit direction (e.g. "fix the about page eyebrow"), do the targeted fix and stop.

---

## Stack reminders, already-decided

- **Ruby 3.4.9 / Rails 8.1.3 / PostgreSQL / Hotwire / Tailwind v4 / Devise / RSpec / Firefox + geckodriver (never Chrome).**
- **Self-hosted fonts only** in `public/fonts/`. No Google Fonts, no Tag Manager, no Analytics.
- **Email-only auth.** No SMS. No phone fields. Ever.
- **Bilingual (en + es) is a merge gate.** Both locales updated in the same PR.
- **CI required checks:** `test`, `lint`, `scan_ruby`, `scan_js`, GitGuardian. Branch protection enforces.
- **Light mode only.** Dark mode was removed 2026-06-16. Do not reintroduce `data-theme`, theme toggles, or `dark:` view classes.
- **Homepage layout:** `/` shows hero + community for signed-out visitors; signed-in users get the dashboard. Features, How it works, and About live at their own routes (`/how-it-works`, `/about`). Don't add content sections back to `/` without owner direction.
- **Nav IA:** Study dropdown (My studies → My notes → Start a study → Join with code) and Explore dropdown (Search → Public notes → Forum → Community Bible → Discover studies). Mobile tab bar mirrors the primary destinations.
- **Editorial content style:** About-page pattern — `max-w-2xl` article, uppercase eyebrow labels, thin `border-t border-surface-200` section dividers, no rounded card chrome on content pages. Apply when touching marketing or settings surfaces.
- **Reader:** verses always render as blocks (one verse per line). No view toggle. Red-letter (Jesus words) enabled. Book picker filters Old/New Testament.
- **OSIS refs** are canonical: `Bible.<TRANSLATION>.<Book>.<Chapter>.<Verse>[!offset]`. Don't reinvent — use `app/services/osis_ref.rb`.
- **Profiles:** vanity URLs at `/@username`. Follow/unfollow on author pages. Forum at `/forum`.
- **Contact form:** live at `/contact`, delivers via `ContactMailer` to `hello@bible-together.org`.
- **Test count:** ~833 spec examples (estimate, 2026-06-17). Full non-JS suite runs in ~10s locally.

---

## Local environment quirks (matters when running specs)

- **Xvfb workaround for Nvidia SWGL deadlock** — the dev box has an Nvidia GPU that makes headless Firefox crash via the SWGL software renderer. `spec/rails_helper.rb` starts a dedicated Xvfb server on `:99` and sets `DISPLAY=:99`; the geckodriver runs Firefox with a real framebuffer instead of headless. If JS specs start hanging (after a reboot or if Xvfb dies), the fix is to reboot or manually run `Xvfb :99 -screen 0 1280x1024x24 &`. CI uses browser-actions/setup-firefox + setup-geckodriver which don't have the GPU issue; headless works fine there.
- **Stale Firefox / geckodriver sessions** can still cause `Net::ReadTimeout` on `Selenium::WebDriver::Remote::Bridge#create_session` even with Xvfb. If a JS spec hangs, kill any orphaned geckodriver/firefox processes (`pkill -f geckodriver && pkill -f firefox`) and re-run. CI is the authoritative validator; don't chase local flakes.
- **Note panel + Turbo Frame testing pattern** — visiting `/notes/:id/edit` directly renders only the partial (no layout, no Stimulus). System specs that need JS features in the panel should visit a reader page and set the turbo-frame `src` via `execute_script`. Example in `spec/system/notes_spec.rb` "post-save flash" spec.
- **Tailwind v4 translate vs transform** — Tailwind v4 uses the CSS `translate` property (not `transform`) for `translate-x-*` utilities. When forcing elements on-screen in specs, set both `element.classList.remove('translate-x-full')` and `element.style.translate = '0 0'`; `element.style.transform` alone has no effect. Production CSS override also uses `translate: 0` (not `transform`), outside all `@layer` blocks so it wins on specificity.
- **`bin/embedding`** boots a Python venv + uvicorn for semantic search; skip with `EMBEDDING_SERVICE_SKIP=1 bin/dev` if you don't need it.
- **Do not pipe rspec output** (`rspec ... | tail`) — hangs forever after js specs because rails_helper's Xvfb inherits stdout. Redirect to a file instead (`> log 2>&1`).
