# REDESIGN.md — Bible Together v2

Owner directive (2026-06-11): the current font, color, and overall design aren't working.
Target feel: **Medium** (reading) + **Grammarly** (friendliness). Very simple, very user
friendly. Core loop: read the Bible (EN/ES) → highlight a verse → leave a note → keep it
private, share it with a Bible study, with friends (mutual follows), or publicly.

This document is the plan of record for the redesign. It covers the design system
replacement (front end) and the social-model completion (back end). `DESIGN.md` gets
rewritten when Sprint R1 lands; until then this file wins where they conflict.

---

## 1. Current-state audit (browser, 2026-06-11)

Audited live with headless Firefox at 1440×1000 and 390×844, light + dark, signed out and
in, across home, how-it-works, sign-in, public bible, personal reader (KJV + RV1909),
search, groups, notes, and settings.

What's hurting us:

1. **The reader — our core surface — is the weakest page.** Verses run together in a
   dense block of smallish Instrument Serif. Instrument Serif is a *display* face
   (high-contrast, spindly at text sizes); at body size it reads old-fashioned and thin.
   Line length and spacing are fine on paper (70ch / 1.8) but the face itself undermines
   them. Medium sets 20px Charter at 1.58 with huge margins; next to that our reader
   feels like a wall of text.
2. **Instrument Serif italic is everywhere** — hero emphasis, empty states, helper copy,
   search subhead, red-letter words. The italics compound the dated feel.
3. **JetBrains Mono eyebrow labels** (`KING JAMES VERSION`, `NO TRACKING. © 2026.`) read
   developer-tool, not friendly consumer product.
4. **The forest mint (#0F5C3F) is somber** and the warm parchment-tinted grays read
   slightly dingy next to Medium/Grammarly pure white.
5. **Search form is a wall of radio buttons** (mode / scope / translation = 7 radios).
6. **Empty states are dashed boxes with italic serif** — sparse, not warm.
7. **"Groups" naming** doesn't match the user's mental model ("join a Bible study").
8. Mobile reader is serviceable but inherits all of the above.

What's already right (keep): sticky blur header, bottom-sheet mobile menus, note panel
slide-over architecture, theme system, a11y discipline, the entire OSIS/highlight/
visibility backend.

---

## 2. Research synthesis

Full notes from the June 2026 platform review (Medium, Grammarly, Readwise Reader,
Hypothes.is, Kindle, Apple Books, YouVersion, Glose/Literal, Notion/Linear/Substack):

**The "simple and friendly" formula Medium and Grammarly share:**

1. One accent color — green — used only where it means something. Everything else is
   white, 2–3 grays, and soft near-black (#242424-family, never #000).
2. Serif for reading at generous size (19–21px / 1.6), neutral sans for chrome.
3. The primary action is **one click from selection** (Medium: select → Highlight;
   Grammarly: Accept). Options come after, not before. Glose measured 3–4× more
   highlights after moving to one-tap.
4. Annotations never sit on top of the text — margins, sidebars, underlines, sheets.
5. Soft geometry: rounded cards, hairline borders, low shadows, generous padding.
6. Human microcopy — one friendly sentence beats an icon cluster.

**Patterns we adopt wholesale:**

- **Hypothes.is visibility-on-the-post-button.** Their Public / Group / Only-Me picker
  lives on the Post button itself ("Post to Public ▾"). Maps 1:1 to our visibility
  model. Visibility becomes a property of the act of posting, not a form section.
- **Kindle's two-layer rendering.** Your highlights = soft background fill. Other
  people's = dotted underline + count ("12 people highlighted"). Crowd marks are never
  louder than your own.
- **Hypothes.is lenses.** You view one annotation layer at a time (Mine / a study /
  Public), switched in the reader — layers don't stack into soup.
- **YouVersion's tap-a-verse → bottom sheet** as the mobile primitive (and *only* that
  from YouVersion — explicitly no feed-home, no streaks, no badges, no verse-image
  generator).
- **Medium's margin chips.** A verse with notes shows a small count chip in the right
  gutter; clicking opens the panel filtered to that verse.
- **Readwise keyboard verbs** for power users: `j`/`k` verse focus, `H` highlight,
  `N` note.

---

## 3. Design System v3 (replaces current DESIGN.md on landing)

### Typography

Two families. Down from three — mono leaves the product UI entirely.

| Role | Face | Notes |
|---|---|---|
| Reading (verses, notes, long-form) | **Source Serif 4** (variable, OFL) | The "small" optical size at 19–20px reads remarkably Charter-like — Medium's DNA, license-clean, full Latin coverage for KJV archaic forms + RV1909 diacritics. Self-hosted woff2 in `public/fonts/`. |
| UI (everything else) | **Inter** (variable, already self-hosted) | Stays. It's exactly the Medium/Grammarly-class neutral; the problem was never Inter. |
| Removed | Instrument Serif, JetBrains Mono | Display serif and mono both leave. Refs/eyebrows become Inter `text-xs font-medium uppercase tracking-wide`. |

Reading body: **20px desktop / 17–18px mobile, line-height 1.7, measure ~680px
(max-w-[42rem])**. Verse numbers: superscript Inter, 0.65em, muted gray.

Fallback stacks: `"Source Serif 4", Georgia, serif` / `Inter, system-ui, sans-serif`.

### Color

Pure white ground, soft near-black text, one fresh green. The warm parchment tint and
the forest mint both go.

| Token | Light | Dark | Usage |
|---|---|---|---|
| `ground` | `#FFFFFF` | `#101113` | Page background |
| `ground-raised` | `#FFFFFF` | `#17181B` | Cards (light mode differentiates by border/shadow, not fill) |
| `ground-sunken` | `#F7F7F5` | `#0B0C0D` | Wells, input fills, sidebar |
| `ink` | `#242424` | `#E8E8E6` | Primary text |
| `ink-secondary` | `#6B6B6B` | `#9C9C9A` | Secondary text, captions |
| `ink-faint` | `#9C9C9C` | `#6E6E6C` | Placeholders, disabled |
| `line` | `#ECECEA` | `#26272B` | Hairline borders, dividers |
| `accent-600` | `#1A8917` | — | **Brand green** (Medium's). Buttons, links, focus. 4.7:1 on white — AA. |
| `accent-700` | `#13700F` | — | Hover/active on light |
| `accent-400` | — | `#4CC38A` | Interactive text/icons on dark |
| `accent-tint` | `#1A8917` @ 8% | `#4CC38A` @ 12% | Selected states, subtle fills |

Hue budget is strict: green = brand/action; highlight pastels = user content; red
reserved for destructive + red-letter; everything else gray. No second chrome hue.

Red-letter (Jesus's words) drops the italic — color alone (`#B42318` light /
`#F97066` dark, AA-checked), upright roman. The italics were half the dated feel.

### Highlight palette (user content)

Four colors + default, Readwise-saturation pastels, fills for *your* marks only:

| Name | Swatch | Light overlay | Dark overlay |
|---|---|---|---|
| Yellow (default) | `#FBDA83` | 45% | 26% |
| Green | `#A9D9A4` | 40% | 24% |
| Blue | `#8DBBFF` | 35% | 24% |
| Rose | `#E4938E` | 35% | 24% |

Other people's highlights render as **dotted underline + count**, never fill.
(Today's five-swatch muted palette migrates: gold→yellow, sage→green, sky→blue,
rose→rose, lavender→blue on a data migration — or keep lavender rows rendering as blue
without touching data; decide in Sprint R3.)

### Geometry, motion, components

- Radius: inputs/buttons 8px, cards 12px, sheets/panels 16px. Pills only for the
  primary CTA and tags.
- Borders: 1px `line` hairlines; shadows only on floating elements (toolbar, sheets,
  popovers) — `0 4px 24px rgb(0 0 0 / 0.08)`.
- Cards: white, hairline border, 20–24px padding. Empty states get a friendly sentence
  + a real CTA button (no dashed boxes, no italics).
- Motion: keep current minimal-functional table; nothing new.
- Buttons: primary = solid `accent-600` white-text rounded-lg; secondary = hairline
  outline ink; destructive = existing two-tier red pattern unchanged.

---

## 4. UX redesign by surface

### 4.1 Reader (the product)

- 680px column, 20px Source Serif 4, white ground. Chrome shrinks: book/chapter title
  row + a quiet toolbar (translation picker, layer switcher, aA settings) that fades on
  scroll-down, returns on scroll-up (Medium pattern).
- **Layer switcher** (new): `Mine ▾ / <each of my studies> / Community` — one lens at a
  time. "Community" replaces the separate `/public/bible` surface eventually; Sprint R7
  decides whether the route merges or stays.
- **Margin note chips**: verses with notes in the active layer get a right-gutter count
  chip; click → note panel filtered to that verse. Community layer adds Kindle-style
  "N highlighted" dotted underlines.
- **Verse-view toggle** in aA settings: continuous prose (default) vs one-verse-per-block
  (study mode). Pure view-layer change.
- Keyboard: `j`/`k` move verse focus, `H` highlight focused verse (default color),
  `N` note, `Esc` closes panel. Discoverable via a `?` overlay.

### 4.2 Highlight → note flow (one-click happy path)

- **Desktop:** select text → dark floating pill toolbar (Medium-style):
  `[Highlight] [Note] [····swatches on hover]`. Click Highlight = yellow, done, zero
  dialogs. Note opens the panel with the citation pre-filled (exists today).
- **Mobile:** tap a verse → dotted-underline selected state → bottom sheet: color row,
  Note, Share, visibility. Multi-tap extends across verses. Long-press drag still does
  character-level. (Today's tap-to-reopen-toolbar from PR #99 evolves into this.)
- **Note composer:** visibility moves onto the Post button — `Post to Only me ▾`
  (Only me / Friends / <study name>… / Public), defaulting to last-used. The amber
  public-warning panel (PR #100) becomes the confirm state inside that menu. Saved
  notes carry a tiny lock/people/globe glyph everywhere they render.

### 4.3 Information architecture

Nav (signed in): **Read · Studies · Community · Search · [avatar]**.

- "Groups" → **"Studies"** everywhere user-facing (EN: "Bible study" / ES: "estudio
  bíblico"). Model/table names stay `Group`/`groups` internally — display-level rename
  + route alias `/studies` (301 from `/groups`).
- **Community** (new page): the public list the owner asked for — a global feed of
  public notes. Card = quoted verse in reading serif + mono-free ref + author note in
  sans + upvote/reply counts. Sort: Recent / Top. Filter by book. This is Medium's
  feed crossed with Literal's quote-cards; built on `Note.public_visible` +
  `sorted_for_public`, paginated.
- Home (signed out) keeps its structure but re-skins; signed-in `/` becomes "continue
  reading" (last chapter, your recent notes, your studies' activity) — reader-first,
  never a feed-first home.

### 4.4 Search

One input + two segmented controls (Verses/Notes/All; This translation/All), semantic
mode folded into a "Meaning" segment next to "Keyword". Radios die. Results: verses as
clean serif blocks with refs, notes as Community-style cards.

### 4.5 Studies (groups) surfaces

Group page becomes the Literal-club pattern: header (name, members, invite), "reading
together" card (current passage link), then a feed of member notes anchored to verses.
Real-time stays as-is (it already broadcasts per-verse). Discovery page re-skins into
card grid.

---

## 5. Backend plan

The visibility model (own / direct share / group / public) already exists and is solid.
What's missing for the owner's spec:

### 5.1 Follows + friends (new)

```ruby
create_table :follows do |t|
  t.references :follower, null: false, foreign_key: { to_table: :users }
  t.references :followed, null: false, foreign_key: { to_table: :users }
  t.timestamps
  t.index [:follower_id, :followed_id], unique: true
end
```

- `User#follow!/unfollow!`, `User#friends` = mutual follows (self-join:
  `follows AS f1 JOIN follows AS f2 ON f1.followed_id = f2.follower_id AND
  f1.follower_id = f2.followed_id`).
- Follow button on `/authors/:id` (page exists); follower/following counts; no
  notification system in v1 (email digest is a later sprint).
- Privacy: follows are public-profile data; profiles only exist where the user already
  has a display name / public notes. No phone, no SMS (Rule 6), nothing changes there.

### 5.2 Friends visibility (new enum value)

Add `friends_note` to the `Note.visibility` enum ("Friends" in the Post-to menu =
all mutual follows, zero-friction). `Note.visible_to(user)` gains a fifth branch:

```sql
OR (notes.visibility = :friends_visibility AND notes.user_id IN (<mutual-follow subquery>))
```

Existing per-person `NoteShare` (User shareable) stays for "share with these specific
people" — but the comma-separated-emails input is replaced by a **friend picker**
(searchable list of mutual follows + "invite by email" fallback). Both paths coexist:
"Friends" = broadcast to all mutuals; picker = enumerated people.

### 5.3 Studies rebrand (display-level)

Route alias `/studies` (+ redirect), i18n sweep (`groups.*` keys gain study wording),
nav label, page copy. DB and class names untouched — churn isn't worth it.

### 5.4 Community feed (new controller, existing data)

`CommunityController#index` over `Note.public_visible.sorted_for_public` with
includes, pagination (Pagy or keyset), book filter via highlight osis_ref prefix.
Upvotes/comments/flagging all exist.

### 5.5 Explicitly not in scope

No OAuth, no SMS/phone (Rule 6), no Chrome tooling (Rule 7), no Google assets (Rule 8),
no streaks/badges/gamification, no notification system in v1, no DB rename of groups.

---

## 6. Sprint sequencing

Each sprint: TDD (Rule 3), UI commits update their system specs in the same commit
(Rule 9), one logical change per commit (Rule 4). The Sprint 12–14 token-migration
playbook (full grep audit → migrate by surface cluster → grep-gated token deletion)
is the template for R1–R4.

| Sprint | Scope | Touches |
|---|---|---|
| **R1 — Tokens + type** | Source Serif 4 woff2 self-hosted; new color tokens added alongside old; reader typography (size/measure/ground); red-letter de-italicized; DESIGN.md rewritten | CSS, layout, reader views |
| **R2 — Chrome re-skin** | Nav/IA (Read·Studies·Community·Search), home, footer, auth pages, settings, empty states, buttons; old-token grep-gate begins | ~20 views |
| **R3 — Highlight/note flow** | Floating pill toolbar, one-click yellow default, mobile verse-tap sheet, Post-to visibility button, note panel card re-skin; highlight palette migration decision | Stimulus controllers, note composer, system specs (`js: true`) |
| **R4 — Reader layers + chips** | Layer switcher (Mine/Studies/Community), margin count chips, dotted community underlines, verse-view toggle, keyboard verbs; old-token deletion (grep-gated) | Reader controllers/views, CSS finale |
| **R5 — Follows** | `follows` table, mutual-follow `friends`, author-page follow UI, counts | New model, author views |
| **R6 — Friends sharing** | `friends_note` enum + `visible_to` fifth branch, friend picker replacing comma emails, Post-to menu wiring | Note model/composer |
| **R7 — Community feed** | `/community` feed (cards, Recent/Top, book filter, pagination); decide `/public/bible` merge | New controller/views |
| **R8 — Studies polish** | `/studies` alias + rename sweep, group page → club layout, discovery card grid | Groups surfaces |
| **R9 — QA pass** | Full-app Firefox screenshot sweep (this audit's script, kept in `script/`), axe on both themes, mobile pass, perf check on chips/layer queries | — |

R5–R9 are expanded into implementation-ready specs in §7 (gap-closure plan).

R1–R4 are sequential (each builds on the last). R5–R6 are sequential with each other
but independent of R3–R4 after R2. R7/R8 can land in either order.

### Owner decisions (2026-06-11) — all four open questions resolved

1. **Accent green: Medium `#1A8917`** (scale as specified in §3).
2. **Reading face: Source Serif 4.**
3. **Existing highlights: render-map, no data migration.** Old stored color names keep
   working and render in the nearest new color (gold→yellow, sage→green,
   sky+lavender→blue, rose→rose). CSS/helper change only; reversible.
4. **`/public/bible` merges into the reader's Community layer** in R7, with 301
   redirects from the old URLs. Signed-out visitors land on the reader with the
   Community layer active.

R1 is unblocked.

---

## 7. Gap-closure plan (added 2026-06-11, post-R4)

R1–R4 shipped the full visual + interaction redesign. This section expands R5–R9
into implementation-ready specs and assigns every known gap — including the small
debts R1–R4 left behind — to a sprint. Nothing on this list is unowned.

### Gap inventory → sprint assignment

| Gap | Sprint |
|---|---|
| No follow system / no mutual-follow friends | R5 |
| No "Friends" option in the Post-to menu | R6 |
| "Specific people" sharing is comma-separated emails | R6 |
| No visibility glyph (lock/people/globe) on rendered notes | R6 |
| No global public feed of notes ("the public list") | R7 |
| `/public/bible` not yet merged into the reader (owner decision #4) | R7 |
| No Kindle-style "N people highlighted" on community underlines | R7 |
| Studies rename is nav-only; pages/emails/URLs still say Groups | R8 |
| Transactional emails still use the old mint in inline styles | R8 |
| Group page isn't the club layout from §4.5 | R8 |
| Verse-view toggle missing on community/study layers | R9 |
| No `?` shortcuts overlay (j/k/h/n undiscoverable) | R9 |
| Devise paranoid mode undecided (account-existence leak) | R9 |
| Full a11y/mobile/perf sweep on the new surfaces | R9 |
| Semantic-search production deployment | Out of scope — backlog (pre-dates redesign) |
| Group default-visibility open question (Sprint 4) | Decide in R6 (recommendation: keep opt-in) |

### R5 — Follows

Foundation for friends. No notifications in v1.

1. **Migration** `create_table :follows`: `follower_id`/`followed_id` (FKs to users,
   `null: false`), timestamps; unique index on `[follower_id, followed_id]`; check
   constraint `follower_id != followed_id`. strong_migrations-safe (new table).
2. **Models.** `Follow` (belongs_to follower/followed, both `class_name: "User"`).
   `User`: `following` / `followers` through follows; `follow!(user)` /
   `unfollow!(user)` / `following?(user)`; `friends` scope via the mutual self-join
   (`follows f1 JOIN follows f2 ON f1.followed_id = f2.follower_id AND
   f1.follower_id = f2.followed_id`); `friends_with?(user)`.
3. **Author page UI** (`/authors/:id` exists): Follow/Following toggle button
   (signed-in, hidden on self), follower/following counts, "Friends" badge when
   mutual. Plain form POST/DELETE → redirect back; no Turbo Streams needed.
4. **FollowsController** `create`/`destroy`, scoped `current_user.follows`.
   404 on self-follow attempts.
5. Follows are public-profile data (consistent with public notes); no privacy
   toggle in v1 — revisit if requested.

TDD: model specs (mutuality, constraint, self-follow), request specs (auth, idempotence),
system spec (toggle on author page). ~4 commits.

### R6 — Friends sharing

1. **Enum append** (integer-backed, append-only): `friends_note: 4` in
   `Note::VISIBILITIES`; add to `NotesController::ACTIVE_VISIBILITIES`.
2. **`Note.visible_to(user)` fifth branch:**
   `OR (notes.visibility = 4 AND notes.user_id IN (<user's mutual-follow ids subquery>))`.
   Admin short-circuit unchanged. Comment visibility inherits via the existing
   `Comment.visible_to` merge — verify with specs, no code expected.
3. **Post-to menu** gains "Friends" between Only me and Specific people
   (en "Friends" / es "Amistades"), with the same data-label mechanics. No share
   sections needed — friends_note is zero-configuration by design.
4. **Friend picker.** The "Specific people" section becomes a checkbox list of the
   author's friends (mutual follows, alphabetical) + the email input demoted to an
   "or invite by email" fallback row. NoteShare semantics unchanged.
5. **Visibility glyphs.** Every rendered note (notes index, note panel header,
   community cards, group lists) shows a tiny glyph + sr-only label for its
   visibility: lock (only me), two-people (friends/specific), book (study), globe
   (public). One shared helper `visibility_glyph(note)`.
6. **Decision to log:** group default visibility stays opt-in per note (Sprint 4
   default) — the Post-to menu makes the choice explicit at write time, which is
   the friction we want.

TDD: visible_to model specs (mutual, one-way, stranger, admin), composer system
specs, glyph helper spec. ~5 commits.

### R7 — Community feed + public-bible merge

1. **`/community` feed** (`CommunityController#index`, public): cards = quoted verse
   (reading serif) + citation + note body + author + upvote/comment counts + posted-at.
   Sort: Recent (default) / Top (`sorted_for_public`). Filter: book select (highlight
   osis_ref prefix). Pagination: `limit/offset` with a "Load more" link (no new gem);
   25/page. Built on `Note.public_visible` + existing includes to avoid N+1.
2. **Nav.** "Community" nav item points to `/community`; the reader's layer switcher
   keeps pointing at the community *reading* layer.
3. **Public-bible merge (owner decision #4):** `Bible::ReaderController` learns
   `?layer=community` — renders the community variant (dotted underlines, public
   notes list, no personal toolbar); `/public/bible/:t/:b/:c` 301-redirects to
   `/bible/:t/:b/:c?layer=community`; signed-out `/bible/...` serves the community
   layer directly instead of redirecting away. Canonical URLs + sitemap updated;
   the old route helpers keep working through the redirect during transition.
   The layer switcher's Community option now stays inside `/bible`.
4. **"N people highlighted."** Community layer chips/underlines gain
   `title`/aria-label "N people highlighted this verse" (distinct highlight authors
   per verse, computed alongside `verse_note_map`).

TDD: feed request + system specs, redirect specs, layer-param specs, count helper
spec. ~6 commits. This is the largest remaining sprint.

### R8 — Studies rename + study page + emails

1. **Routes:** `resources :groups, path: "studies"` (helpers unchanged) + 301
   redirect `/groups/*` → `/studies/*` for bookmarks/SEO.
2. **Copy sweep:** all `groups.*` i18n values to study wording (en + es) — page
   headings, buttons, flashes, invitation email subject/body. Model/table/helper
   names stay `Group`/`groups` (display-level rename per the original decision).
3. **Study page → club layout (§4.5):** header (name, members, invite),
   "reading together" card linking the group's current chapter, then the member-notes
   feed anchored to verses. Real-time wiring untouched.
4. **Discovery** page becomes the card grid.
5. **Mailer re-skin:** transactional emails (Devise + invitations) get the v3 green
   and Source Serif inline styles — closes the stale-mint debt.

TDD: redirect specs, system sweep label updates, mailer specs. ~5 commits.
Highest spec-churn sprint (label assertions), lowest risk.

### R9 — QA + hardening (close-out)

1. Full `script/design_audit.rb` sweep — all surfaces × both themes × desktop/mobile;
   fix visual nits found.
2. axe-core on every surface including the new ones (community feed, author pages,
   Post-to menu open state) — both themes.
3. **Small debts:** verse-view toggle on community/study layers; `?` keyboard
   shortcuts overlay (one modal listing j/k/h/n + Esc, aria-modal, closes on Esc).
4. **Perf:** verify chip/layer/feed queries N+1-free under log inspection; add any
   missing indexes surfaced by the follows/friends subqueries.
5. **Security gate:** flip `config.devise.paranoid = true` (account-existence leak
   matters more once follows make user enumeration interesting); re-run brakeman +
   bundler-audit; review FollowsController for IDOR.
6. Decisions-log close-out + REDESIGN.md marked complete; README screenshots refresh.

### Sequencing

```
R5 ──► R6 ──┐
            ├──► R9
R7 ─────────┤
R8 ─────────┘
```

R5→R6 is the only hard dependency. R7 and R8 are independent of both and of each
other — they can interleave if priorities shift (e.g., ship R7 first if the public
feed matters most). R9 is last, always.

Estimated effort at the R1–R4 pace: R5 and R8 are single-session sprints; R6 and R7
are larger; R9 is a half-session. The user-facing goal statement is fully satisfied
at the end of R7; R8–R9 are finish work.
