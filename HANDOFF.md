# HANDOFF.md

> Read this first when picking up the project in a fresh Claude session.
> Goal: orient in under 60 seconds, then go to the right doc for depth.

---

## Where things are right now

- **Production:** [bible-together.org](https://bible-together.org), live since 2026-04-21, on Render. `main` auto-deploys.
- **Repo:** Public on GitHub as [Bij4n/bible-together](https://github.com/Bij4n/bible-together) (MIT). Local checkout: `~/projects/bible-together` (renamed from `open-bible` 2026-06-15).
- **Branch:** `sprint-r7-community` — R7–R9 complete locally; merge to `main` when ready.
- **Redesign (REDESIGN.md R1–R9):**
  - **Shipped on `main`:** R1 tokens/type (Source Serif 4, Medium green `#1A8917`, white ground), R2 chrome re-skin, R3 highlight/note flow, R4 reader layers + chips, R5 follows, R6 friends sharing.
  - **On branch (ready to merge):** R7 community feed + public-bible merge; R8 `/studies` rename + club layout; R9 verse-view on all layers, keyboard `?` help, community axe baseline, Devise paranoid mode.
  - **Design source of truth:** `DESIGN.md` (v3). Rationale + sprint breakdown: `REDESIGN.md`.
  - **Brand assets:** `public/icon.svg`, `public/icon.png` (v3 green concentric mark + pair dots), header `.wordmark-mark` disc. Preview page: `public/logo-preview.html` (research artifact — may lag DESIGN.md).
- **GitHub Discussions:** Live. Welcome post pinned as discussion #92 in Announcements.

- **Previous cluster (2026-05-26, PR #111):** post-Sprint-25 UI polish + homepage redesign. See git history for detail.

---

## What to read next, in order

1. **`CLAUDE.md`** — workflow rules (the 9 numbered rules, especially Rule 7 no-Chrome / Rule 8 no-Google-fonts / Rule 9 every-UI-commit-ships-its-spec), TDD discipline, commit style, confidence flagging.
2. **`PLAN.md` "Current sprint"** (top of file) — one-paragraph statement of where we are and what's queued. Keep this current as the project moves.
3. **`PLAN.md` decisions log** — the most recent ~5 entries are append-only context for *why* the current code is what it is. Grep here when something looks wrong before assuming it's wrong.
4. **`PROJECT_OVERVIEW.md`** — depth reference (stack, file tour, sprint history). Slower to read; only when you actually need it.

---

## Open questions / where the user needs to weigh in

These are the things sitting on the user's desk, not Claude's. Don't pick them blind.

- **Legal pages** — `/terms`, `/privacy`, `/acceptable-use`. Sprint 15 blocker, still open. More pressing now that the repo is public and the app is accepting donations. Needs jurisdiction decision + drafted copy from the owner before any code can be written.
- **Devise paranoid-mode stance** — `paranoid = true` on branch (Sprint R9); merge when ready.
- **Language-switcher placement** — the account-sheet is overloaded (theme + locale + auth all in one dropdown). Two options exist; owner picks. Audit detail saved at `~/.claude/plans/what-do-you-need-enumerated-ember.md`.
- **Pencil-bridge polish** (Sprint 16.5 PR E) — transition between toolbar dismiss and note-panel reveal. No UX spec locked: slide animation? auto-focus scroll? back-arrow to reopen toolbar? Owner decides the gesture before building.
- **Contact form** — delivery channel undecided (Resend mailer pipe? Slack hook? Ticket queue?). Ready to build the moment the channel is decided.
- **Donation rotation UX redesign** — current behavior forces a rotation on every "Add address." Backlogged design call: `Add` creates inactive, separate `Activate` action promotes. Low urgency; current behaviour works.
- **Issue triage process** — now that the repo is public, how fast and by what criteria does the owner respond to incoming GitHub issues? No tooling needed; just a mental model to have.

---

## Next session queue

**Owner input needed first:**
- **Language-switcher placement** — once decided, this is a focused Stimulus + CSS change. No code until the owner picks an option.
- **Pencil-bridge polish** — same; the build is straightforward once the UX is specified.

**Autonomous-doable (no owner input needed):**
- **Swipe-to-dismiss bottom sheet** — the mobile highlight toolbar (PR #50) and account menu have no swipe gesture. Substantive Stimulus + gesture work; roughly a full sprint segment.
- **Public author profiles** — `/authors/:slug` showing public notes by an author. Useful now that public notes exist and accumulate.
- **Multilingual semantic search (4-step sequenced)** — see `PROJECT_OVERVIEW.md` §8 for the full plan. Currently Concept search is English-only and labeled as such; multilingual covers RV1909. Steps: (1) make `embeddings.rake` translation-agnostic, (2) swap to multilingual model, (3) regenerate embeddings, (4) drop the "(English)" parenthetical from homepage.
- **`/help` or FAQ** — usage guide. No clear demand yet; easy to add.

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
- **Theme system:** `data-theme="dark"` attribute on `<html>` set by `theme_controller.js` from server pin / localStorage / system; CSS uses `@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *))`. No-flash theme script is in `<head>` as an inline `<script>` — sets `data-theme` before any stylesheet evaluates.
- **Homepage layout (as of PR #111):** `/` shows only hero + community. Features grid, How it works, and About live at `/how-it-works`. Don't add content sections back to `/` without owner direction.
- **OSIS refs** are canonical: `Bible.<TRANSLATION>.<Book>.<Chapter>.<Verse>[!offset]`. Don't reinvent — use `app/services/osis_ref.rb`.
- **Test count:** ~800+ (estimate post PR #111 additions; last confirmed count was ~786 as of 2026-05-12). Full non-JS suite runs in ~10s locally.

---

## Local environment quirks (matters when running specs)

- **Xvfb workaround for Nvidia SWGL deadlock** — the dev box has an Nvidia GPU that makes headless Firefox crash via the SWGL software renderer. `spec/rails_helper.rb` starts a dedicated Xvfb server on `:99` and sets `DISPLAY=:99`; the geckodriver runs Firefox with a real framebuffer instead of headless. If JS specs start hanging (after a reboot or if Xvfb dies), the fix is to reboot or manually run `Xvfb :99 -screen 0 1280x1024x24 &`. CI uses browser-actions/setup-firefox + setup-geckodriver which don't have the GPU issue; headless works fine there.
- **Stale Firefox / geckodriver sessions** can still cause `Net::ReadTimeout` on `Selenium::WebDriver::Remote::Bridge#create_session` even with Xvfb. If a JS spec hangs, kill any orphaned geckodriver/firefox processes (`pkill -f geckodriver && pkill -f firefox`) and re-run. CI is the authoritative validator; don't chase local flakes.
- **Note panel + Turbo Frame testing pattern** — visiting `/notes/:id/edit` directly renders only the partial (no layout, no Stimulus). System specs that need JS features in the panel should visit a reader page and set the turbo-frame `src` via `execute_script`. Example in `spec/system/notes_spec.rb` "post-save flash" spec.
- **Tailwind v4 translate vs transform** — Tailwind v4 uses the CSS `translate` property (not `transform`) for `translate-x-*` utilities. When forcing elements on-screen in specs, set both `element.classList.remove('translate-x-full')` and `element.style.translate = '0 0'`; `element.style.transform` alone has no effect. Production CSS override also uses `translate: 0` (not `transform`), outside all `@layer` blocks so it wins on specificity.
- **`bin/embedding`** boots a Python venv + uvicorn for semantic search; skip with `EMBEDDING_SERVICE_SKIP=1 bin/dev` if you don't need it.
