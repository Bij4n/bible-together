# HANDOFF.md

> Read this first when picking up the project in a fresh Claude session.
> Goal: orient in under 60 seconds, then go to the right doc for depth.

---

## Where things are right now

- **Production:** [bible-together.org](https://bible-together.org), live since 2026-04-21, on Render. `main` auto-deploys.
- **Repo:** Public on GitHub as [Bij4n/bible-together](https://github.com/Bij4n/bible-together) (MIT). Local checkout: `~/projects/bible-together`.
- **Branch:** `main` — all work through PR #205 merged and live (2026-10-11). #206 (study form tidy-up) and the docs refresh were open at the end of that session.
- **Design source of truth:** `DESIGN.md` (v3). Rationale + sprint breakdown: `REDESIGN.md` (R1–R9 shipped on `main`).

### Shipped 2026-10-10 → 2026-10-11 — Highlighted in Red

The project is now focused on the words, parables and encounters of Jesus. All seven sprints of the plan and the follow-ups are merged and live (PRs #184–#205). Sprint table, owner decisions and what's left are at the top of `PLAN.md`.

- **The section:** `/red` (front page), `/red/words` (first red chapter), `/red/:translation/:book/:chapter` (the red reader), `/red/parables`, `/red/encounters`, `/red/sayings`, `/red/themes`, and `/red/<list>/<slug>` for a single passage.
- **Data:** `config/passages.yml`, `config/themes.yml`, `config/red_letter/kjv.yml` and `rv1909.yml`. Editing the first two needs no deploy step. After editing a file under `config/red_letter/` (`kjv.yml` or `rv1909.yml`), run `bundle exec rails 'bible:red_letter:apply[<code>]'` in the Render shell.
- **Nav IA:** top level is Read · In Red · Study · Explore. Study dropdown (My studies → My notes → Start a study → Join with code) and Explore dropdown (Search → Public notes → Forum → Community Bible → Discover studies). The mobile tab bar has five tabs: Read, In Red, Study, Explore, You.
- **Study focus:** `users.study_focus` (settings) and `groups.focus` (new-study form).
- **Study reading lists:** `groups.reading_list` (`parables`, `encounters`, `sayings` or `theme:<slug>`) and `groups.current_passage`. A list study reads at `/studies/:id/passages/:slug`; a manager moves the "We are here" marker by hand. `Group#plan` is the single form value covering focus and list.
- **Search:** `?red=1`, "Search only the words of Jesus". Keyword search then runs against `verses.red_text` (his words on their own, written by the importer, the KJV mirror and the red-letter patch). Concept search still filters by verse.
- **Explanations:** a passage in `config/passages.yml` can carry `explained:` (same chapter, after the telling); the page shows it under the telling. Set for the Sower and the Wheat and the Weeds.
- **Also in this cluster:** the brakeman/mail/rubyzip bump, the `/studies#join` anchor, the community-layer fix for notes on phrase-level highlights, the About page rewrite and the *Donate to the Mission* heading.
- **Watch for:** `bin/brakeman` runs with `--ensure-latest`, so `scan_ruby` fails on every branch the day a new brakeman is released; bump brakeman first. `spec/system/public_bible_spec.rb:54` failed once in CI and passed on re-run.
- **Merging:** in the session that built this, `gh pr merge` was blocked by the session's permission settings, so the owner merged every PR by hand.

### Shipped 2026-08-06 — contact form data loss + security bump

- **The contact form was a black hole for three days.** A bot submission hard-bounced `hello@bible-together.org`, Resend suppressed the address account-wide, and every later submission was dropped while the visitor still saw a success message. `ContactMessage` (PR #169) now persists the row *first* and treats email as a notification; honeypot + per-IP rate limit added (PR #172). Full story in the `PLAN.md` decisions log — read it before touching mail code, especially the part about `raise_delivery_errors` not covering suppression.
- **Inbound mail moved Proton → Google Workspace** on the apex. The Resend `send.` subdomain was untouched, which is why outbound never broke.
- **Nine gems bumped for open advisories** (PR #171), including a high-severity `websocket-driver` DoS. `scan_ruby` was failing for `bundler-audit`, not Brakeman. **`bin/bundler-audit` now passes `--update`** (PR #174) — CI clones the advisory database fresh every run, so a stale local copy used to report clean while CI failed on the same lockfile.
- **Docs corrected** (PR #173) — mail topology, legal-page status, test count, and the local Xvfb footguns.
- **Resend failure webhook** — `POST /webhooks/resend` records bounces, complaints, failures, suppressions, and suppression-list changes as `MailEvent` rows. Svix signature verified in-house (no new gem). **Needs two setup steps before it does anything** — see the Resend webhook note in `PROJECT_OVERVIEW.md`. Recording only; no alerting yet, by design.

### Shipped earlier (2026-06-16 → 2026-06-17)

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

- **Legal pages** — `/terms` and `/privacy` **shipped** (`LegalController`, live and serving 200, copy in both locales). Only `/acceptable-use` is still open: unrouted, no view. Needs a jurisdiction decision + drafted copy from the owner. Note there are **no request specs for `LegalController`** — a coverage gap worth closing when the third page lands.
- **Groups / studies deep-dive** — owner wants a full pass on how groups work: highlighting, notes, sharing, settings, and administrator workflows. Studies gained a focus and reading lists in October 2026; the audit itself is still open.
- **Language-switcher placement** — the account menu still carries locale + auth. Two options exist; owner picks. Audit detail saved at `~/.claude/plans/what-do-you-need-enumerated-ember.md`.
- **Pencil-bridge polish** (Sprint 16.5 PR E) — transition between toolbar dismiss and note-panel reveal. No UX spec locked: slide animation? auto-focus scroll? back-arrow to reopen toolbar? Owner decides the gesture before building.
- **Donation rotation UX redesign** — current behavior forces a rotation on every "Add address." Backlogged design call: `Add` creates inactive, separate `Activate` action promotes. Low urgency; current behaviour works.
- **Issue triage process** — now that the repo is public, how fast and by what criteria does the owner respond to incoming GitHub issues? No tooling needed; just a mental model to have.

---

## Next session queue

**Owner input needed first:**
- **Finish wiring the Resend webhook (two steps, ~5 minutes).** Owner planned to do this on 2026-10-12. The code shipped in PR #175 but is **inert** until both are done, and returns 500 on every delivery in the meantime — deliberately, so a missing secret is loud. (1) Register `https://bible-together.org/webhooks/resend` in Resend → Webhooks, subscribed to `email.bounced`, `email.complained`, `email.failed`, `email.suppressed`, `email.delivery_delayed`, `suppression.added`, `suppression.removed`. (2) Put the generated `whsec_…` secret into credentials as `resend.webhook_secret`. Details in `PROJECT_OVERVIEW.md`.
- **Pick the alert channel** for `MailEvent` failures. Recording works; nothing pushes. It can't be email — that's what breaks. Options: a second address on a different provider, or opening a GitHub issue via the API.
- **Check study focus and a list study on the live site, signed in.** Both were walked through locally against the full data and in CI, but not on production, which needs an account. Settings → "What you study"; Start a study → "What this study reads".
- **Review the softened About copy** (#198). The PR lists the three places the wording differs from the owner's notes.
- **Legal pages** — `/terms` and `/privacy` shipped; only `/acceptable-use` remains. Needs jurisdiction + copy from owner before any code.
- **Language-switcher placement** — once decided, this is a focused Stimulus + CSS change. No code until the owner picks an option.
- **Pencil-bridge polish** — same; the build is straightforward once the UX is specified.
- **Groups / studies audit** — still open as a full pass, though studies gained focus and reading lists in October.

**Autonomous-doable (no owner input needed):**
- **Multilingual semantic search (4-step sequenced)** — the largest item left. See `PROJECT_OVERVIEW.md` §8. Concept search is English-only, so it and its "words of Jesus" filter do nothing useful for RV1909. Steps: (1) make `embeddings.rake` translation-agnostic, (2) swap to a multilingual model, (3) regenerate embeddings (a 15–20 minute job in the Render shell, so it needs the owner at the end), (4) drop the "(English)" parenthetical from the homepage.
- **Concept search inside his words.** The filter is verse-level there. Would need embeddings of the red text alone.
- **More explanations and passages.** One line each in `config/passages.yml`.
- **Local browser-suite reliability.** Still fails a handful to a few dozen examples per full run when the machine is under load (see the local quirks section). `rails_helper.rb` still starts Xvfb with a fixed `sleep 1`; polling for the display and falling back to `-headless` is the untried part.
- **Alerting on top of `MailEvent`** — once the owner picks a channel.
- **Swipe-to-dismiss bottom sheet** — the mobile highlight toolbar and account menu have no swipe gesture. Roughly a full sprint segment.
- **`/help` or FAQ** — usage guide. No clear demand yet; easy to add.
- **Profile social layer polish** — liking and commenting on notes from profile pages.
- **Remaining editorial surfaces** — forum thread show, notes show, admin pages, and Devise mailer HTML still carry pre-redesign card chrome.
- **Open dependency PRs.** A dozen Dependabot PRs have been open since June–August; most went red only because of the `scan_ruby` problem fixed in #184 and need a rebase. `image_processing` 2.x and `thruster` failed `test` on their own and need a look.

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
- **Homepage layout:** `/` shows hero, the three feature cards, a short Highlighted in Red introduction and the community section for signed-out visitors; signed-in users get the dashboard (continue reading, a Highlighted in Red card, recent notes, studies). Features, How it works, and About live at their own routes (`/how-it-works`, `/about`). Don't add further content sections to `/` without owner direction.
- **Nav IA:** Study dropdown (My studies → My notes → Start a study → Join with code) and Explore dropdown (Search → Public notes → Forum → Community Bible → Discover studies). Mobile tab bar mirrors the primary destinations.
- **Editorial content style:** About-page pattern — `max-w-2xl` article, uppercase eyebrow labels, thin `border-t border-surface-200` section dividers, no rounded card chrome on content pages. Apply when touching marketing or settings surfaces.
- **Reader:** verses always render as blocks (one verse per line). No view toggle. Red-letter (Jesus words) enabled. Book picker filters Old/New Testament. The red reader, passage pages and study reader are all this same reader: the red lens is a class on the page plus a data-derived `verse-narration` class on each verse, never a different rendering of a verse, so live verse replaces can't switch it off.
- **About page:** states why the site exists, quotes Jesus five times with links into the red reader, and gives the founder's story in the first person. Owner's voice; don't soften or sharpen it without asking.
- **OSIS refs** are canonical: `Bible.<TRANSLATION>.<Book>.<Chapter>.<Verse>[!offset]`. Don't reinvent — use `app/services/osis_ref.rb`.
- **Profiles:** vanity URLs at `/@username`. Follow/unfollow on author pages. Forum at `/forum`.
- **Contact form:** live at `/contact`. Submissions **persist as `ContactMessage` rows first**, then `ContactMailer` notifies `hello@bible-together.org`. The email is a notification, not the transport — a Resend suppression silently destroyed every submission for three days in Aug 2026. Guarded by a honeypot (`website` field) plus a per-IP `rate_limit` of 5/hour. No admin UI; read them from the console, same as `DonationReport`.
- **Test count:** about 1,220 spec examples, about 130 of them tagged `js: true` (measured 2026-10-11 via `rspec --dry-run`). The non-JS suite runs in ~15s locally; the JS ones are only reliable in CI (see the Xvfb note below).

---

## Local environment quirks (matters when running specs)

- **Xvfb workaround for Nvidia SWGL deadlock** — the dev box has an Nvidia GPU that makes headless Firefox crash via the SWGL software renderer. `spec/rails_helper.rb` starts a dedicated Xvfb server on `:99` and sets `DISPLAY=:99`; the geckodriver runs Firefox with a real framebuffer instead of headless. If JS specs start hanging (after a reboot or if Xvfb dies), the fix is to reboot or manually run `Xvfb :99 -screen 0 1280x1024x24 &`. CI uses browser-actions/setup-firefox + setup-geckodriver which don't have the GPU issue; headless works fine there.
- **Stale Firefox / geckodriver sessions** can still cause `Net::ReadTimeout` on `Selenium::WebDriver::Remote::Bridge#create_session` even with Xvfb. The orphan to look for is a `firefox --marionette ... -profile /tmp/rust_mozprofile*` process; while one is alive, every new session creation times out (~4 min each), so a suite appears to hang. Kill orphans and re-run. CI is the authoritative validator; don't chase local flakes.

  **Use the bracket trick when killing:** `pkill -f "[f]irefox"`, not `pkill -f firefox`. The plain form matches the *pkill command line itself* and kills your own shell — it looks like the terminal died for no reason. Same for geckodriver. Full cleanup: `pkill -9 -f "[m]arionette"; pkill -9 -f "[f]irefox-bin"; pkill -9 -f "[g]eckodriver"; rm -rf /tmp/rust_mozprofile*`.

- **Window size between js examples** (2026-10-11). Under Xvfb a resize isn't applied by the time the call returns, so one example's restore could land after the next example's resize. `spec/support/window_size.rb` restores the opening size after every js example and waits for it to land; use its `at_window_size(w, h) { ... }` (or `WindowSize.resize_and_settle`) for any phone-width example instead of a bare `resize_to`. **This reduced the local failures but did not end them.** Right after the change the full browser suite passed three times in a row; an hour later, with the machine under memory pressure and runs taking twice as long, it failed between 6 and 35 examples per run, mostly the same six as before (`group_invitations:32`, `highlights:120` and `:477`, `reader_note_markers:34`, the two `site_nav` mobile tab bar examples). Those look like timing under load, not window size. CI stays the authority for js specs.

- **Three ways the local JS setup self-sabotages** (diagnosed 2026-08-06; `rails_helper.rb` not yet changed, so these are live footguns):
  1. The helper does `system("Xvfb :99 … &")` then `sleep 1` — but Xvfb needs ~2s to accept connections on this box. It's a race.
  2. It then sets `ENV["DISPLAY"] = ":99"` **unconditionally**, without re-checking that Xvfb came up. So a failed or slow start silently becomes a 4-minute `create_session` timeout instead of a clear error or a `-headless` fallback.
  3. Xvfb is spawned inside the rspec process group, so killing a run (`timeout`, Ctrl-C) takes Xvfb down with it — **one killed run poisons every run after it.** Start Xvfb yourself outside the runner if you're iterating: `Xvfb :99 -screen 0 1400x1024x24 -ac +extension GLX +render &`.

  Verify before blaming the specs: `DISPLAY=:99 xdpyinfo >/dev/null && echo alive`. Note `kernel.apparmor_restrict_unprivileged_userns = 1` is set on this box, the condition `rails_helper.rb` mitigates with `security.sandbox.content.level = 0`.
- **Note panel + Turbo Frame testing pattern** — visiting `/notes/:id/edit` directly renders only the partial (no layout, no Stimulus). System specs that need JS features in the panel should visit a reader page and set the turbo-frame `src` via `execute_script`. Example in `spec/system/notes_spec.rb` "post-save flash" spec.
- **Tailwind v4 translate vs transform** — Tailwind v4 uses the CSS `translate` property (not `transform`) for `translate-x-*` utilities. When forcing elements on-screen in specs, set both `element.classList.remove('translate-x-full')` and `element.style.translate = '0 0'`; `element.style.transform` alone has no effect. Production CSS override also uses `translate: 0` (not `transform`), outside all `@layer` blocks so it wins on specificity.
- **`bin/embedding`** boots a Python venv + uvicorn for semantic search; skip with `EMBEDDING_SERVICE_SKIP=1 bin/dev` if you don't need it.
- **Do not pipe rspec output** (`rspec ... | tail`) — hangs forever after js specs because rails_helper's Xvfb inherits stdout. Redirect to a file instead (`> log 2>&1`).
