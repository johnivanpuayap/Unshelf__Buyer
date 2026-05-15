# Unshelf Buyer App — UI/UX Redesign Spec

> Date: 2026-05-16
> Status: Draft for review
> Sub-project: 3.1 of the Unshelf rebrand decomposition (follow-on to sub-project 3, the rebrand)
> Repo: `personal-projects/unshelf-buyer/` · https://github.com/johnivanpuayap/unshelf-buyer

## Context

Sub-project 3 (the buyer rebrand, shipped 2026-05-16 as 4 phase PRs) applied brand tokens to existing layouts and migrated state management. It did not redesign screens. The result was visually inconsistent — color/font swaps on top of layouts that were never designed with a system in mind. The auth screens demonstrated the gap: overlapping inputs, half-rendered logo (CSS-class SVG issue), tight spacing, basic buttons.

The auth screens were redesigned in commit `f8fa8b5` (PR #13) to set the quality bar. This sub-project applies the same redesign discipline to **every other surface** of the buyer app.

Auth screens are also being treated as a **shared component** between buyer and seller — both apps will conform to the same design, captured in `brand-kit/docs/crucible/auth-screens.md` (committed 2026-05-16 to the brand kit). This sub-project ships the buyer side; the seller's auth implementation lives in its own sub-project later.

## Scope

**In:**
- Full surface-by-surface redesign of all non-auth screens — composition, spacing, typography hierarchy, real components instead of ad-hoc Containers
- Extract reusable composed components into `lib/components/` as patterns emerge (ProductCard, StoreCard, BasketRow, SectionHeader, EmptyState, AppShell, etc.) — design-system-by-extraction, not design-system-up-front
- Apply Soft Editorial principles consistently per `brand-kit/docs/crucible/design.md` — pill buttons, 14px card corners, two-layer shadows, generous spacing, no glassmorphism, no pure-white surfaces
- Plain transactional copy on all action buttons per `feedback_unshelf_copy` memory rule
- Empty-state, error, and loading affordances per screen (where currently missing)
- Conform to the auth-screens spec for buyer's login + register (already mostly done in PR #13 — confirm + document)

**Out:**
- Feature additions / new screens
- Payments cleanup (Stripe → PayMongo) — own sub-project
- Comprehensive test coverage — own sub-project
- Store-submission polish (real app icon export, splash, store listings) — own sub-project
- Seller app — its own sub-project. **The seller app is intentionally NOT going to share most UI with the buyer.** See "Uniqueness rule" below.
- Backend / Firestore schema changes
- Performance optimization beyond what falls out naturally from cleaner widget trees

## Uniqueness rule (applies to this AND the seller sub-project)

Buyer and seller apps share **brand identity** (palette, typography, logo, Soft Editorial principles, copy voice rules) but are intentionally **visually + structurally distinct** from each other.

**Shared between buyer and seller — must stay identical:**

- Brand tokens (via brand-kit submodule)
- Logo assets (via brand-kit submodule)
- Full auth flow per `brand-kit/docs/crucible/auth-screens.md`:
  - Sign in
  - Sign up / register
  - Forgot password (request + confirmation)
  - Reset password (if/when in-app)
  - Verify email (if/when implemented)
- Soft Editorial principles (applied independently — same RULES, not same widgets)
- Copy voice rules (applied independently)

**NOT shared:**

- Home / dashboard (buyer = marketplace; seller = inventory + orders)
- Navigation structure (each app picks what fits its user)
- Product screens (buyer browses; seller manages)
- Order screens (different perspectives)
- Profile / settings (different fields)
- Component implementations (`ProductCard` in buyer is shopper-facing; the seller's equivalent is inventory-facing — they are different components, not a shared one)

**For this sub-project:** do not build any `lib/components/` widget with seller-shareability in mind. Build for the buyer's use case. The seller will get its own components when its sub-project happens — sharing brand TOKENS, not WIDGETS.

This rule is captured in memory `[[unshelf-buyer-seller-uniqueness]]`. If a future session tries to lift buyer code into a shared package or vice versa, flag and revert.

## Concept summary

| Decision | Value |
|---|---|
| Visual identity | Inherited from brand kit (Leaf & Honey palette, DM Serif Display + DM Sans, Soft Editorial style) |
| Quality bar | The redesigned auth screens in `lib/authentication/views/` (PR #13) — that's the floor every other screen meets |
| Component strategy | Extract patterns into `lib/components/` as they emerge, not upfront. Three uses → extract |
| Auth consistency | Buyer's auth matches the spec at `brand-kit/docs/crucible/auth-screens.md`. Seller will duplicate the same spec in its own sub-project |
| Branch strategy | Per-screen-group branch, PR-per-group into `main`, squash-merge |
| Repo | `personal-projects/unshelf-buyer/` (renamed 2026-05-16) |
| Git identity | `johnivanpuayap@gmail.com` (already configured) |

## Approach

**Surface-by-surface, not big-bang.** Each screen group is redesigned, tested, PR'd, and merged before the next starts. Each PR is independently shippable — the app remains in a green state at every checkpoint.

**Three uses → extract.** Don't pre-design a component library. As redesigned screens reveal duplicate patterns, extract them into `lib/components/`. This keeps the design system grounded in real usage.

**Reference the brand kit, not your imagination.** When designing a screen, open `brand-kit/docs/crucible/preview.html` in a browser for the component reference, and `brand-kit/docs/crucible/design.md` for the token / type / spacing scale. Don't invent.

## Screen groups (in this order)

Order is roughly "most-visible first" so progress is felt early. Each group is one PR.

### Group A — Auth (full flow + ship)

PR #13 was closed without merge — its work is now subsumed into this group. Group A implements the **full auth flow** to match `brand-kit/docs/crucible/auth-screens.md`:

- `lib/authentication/views/login_view.dart` — rebuild per spec
- `lib/authentication/views/register_view.dart` — rebuild per spec
- `lib/authentication/views/forgot_password_view.dart` — **NEW** (request screen)
- `lib/authentication/views/reset_email_sent_view.dart` — **NEW** (confirmation screen)
- `assets/images/logos/logo.svg` and `logo-icon.svg` — rewrite with inline fills (no CSS classes); `flutter_svg` can't reliably resolve `<style>` + `class=""`
- `lib/theme/unshelf_theme.dart` — refine `InputDecorationTheme` per spec (16/16 padding, hint @ 45%, floating label in primary, 12px radius @ 1.2 weight, error border)

**The auth spec is the contract.** When the seller's sub-project happens, the seller implements the same four screens to the same spec — same layout, same copy, same behavior. Only differences allowed: role check (`type == 'seller'` vs `'buyer'`), after-login route, and the extra "Store name" field on the seller's register screen (documented in the auth spec).

### Group B — Home + dashboard

- `lib/views/home_view.dart` — main landing for buyers. Per memory rule `[[unshelf-rebrand]]`: the main dashboard is **products**, not stats. Show: category quick-filters, "Nearby" stores, "Expiring soon" listings, search affordance.
- `lib/views/notifications_view.dart`

Components that may emerge: `SectionHeader`, `CategoryChip`, `ProductCardCompact`, `StoreCard`.

### Group C — Browsing

- `lib/views/category_view.dart` — products in a category
- `lib/views/search_view.dart` — search results + filters
- `lib/views/stores_view.dart` — store directory
- `lib/views/store_view.dart` — single store detail with their listings
- `lib/views/store_reviews_view.dart`

Components: `ProductCard` (full), `StoreCard`, `FilterChipRow`, `EmptyState`.

### Group D — Product detail + reviews

- `lib/views/product_view.dart` — main product detail with image carousel, badges, store info, CTA
- `lib/views/product_bundle_view.dart` — bundle detail
- `lib/views/review_view.dart` — leave a review

Components: `ProductHero`, `ExpiryBadge`, `PriceBlock`, `QuantityStepper`, `ReviewItem`.

### Group E — Basket + checkout

- `lib/views/basket_view.dart` — basket list with stepper, totals
- `lib/views/basket_checkout_view.dart` — order review with address, payment, pickup window
- `lib/views/order_placed_view.dart` — success state
- `lib/views/order_address_view.dart` — address selection (map embed already on FlutterMap)

Components: `BasketRow`, `OrderSummaryCard`, `AddressTile`, `PickupWindowPicker`.

### Group F — Orders + tracking

- `lib/views/order_history_view.dart` — order list
- `lib/views/order_details_view.dart` — single order with items, status, store
- `lib/views/order_tracking_view.dart` — status timeline with map
- `lib/views/profile_orders_view.dart` (currently empty file — confirm if needed; delete if orphan)

Components: `OrderCard`, `OrderStatusTimeline`, `OrderItemRow`.

### Group G — Profile + settings + addresses

- `lib/views/profile_view.dart` — user profile + nav to subsections
- `lib/views/edit_profile_view.dart`
- `lib/views/profile_favorites_view.dart`
- `lib/views/profile_following_view.dart`
- `lib/views/edit_address_view.dart` (currently fully commented — confirm scope: rebuild or remove)
- `lib/views/store_address_view.dart` — view a store's location on map

Components: `ProfileHeader`, `SettingsTile`, `ListGroupSection`, `AvatarBubble`.

### Group H — Chat + reports + map

- `lib/views/chat_view.dart` — chat list
- `lib/views/chat_screen.dart` — single conversation
- `lib/views/report_view.dart` — report a product/store
- `lib/views/map_view.dart` — standalone map (FlutterMap already in place; this redesigns surrounding UI)

Components: `ChatThreadTile`, `MessageBubble`, `MapFilterSheet`.

### Group I — Shared components final pass

- Audit `lib/components/` (existing + emergent during groups B–H)
- Promote any single-use widget that appears in 3+ places to a named, documented component
- Add a `lib/components/README.md` listing every component with its purpose, props, and example usage
- Remove ad-hoc widgets superseded by the design system

## Testing approach

Per the deferred-tests decision (carried from sub-project 3):

1. **Preservation:** the 41 existing tests (theme + viewmodels + Nominatim) must remain green after every group.
2. **New components with non-obvious contracts:** if a component has stateful logic worth pinning (e.g., `QuantityStepper` clamping, `PickupWindowPicker` validation), add a widget test for it. Most components are presentational — no test needed.
3. **No comprehensive widget test suite.** That's the future test-coverage sub-project.

Each group's PR must include `flutter test` output showing 41+ tests still green.

## Acceptance criteria

The sub-project is done when:

1. ⬜ Every non-auth screen group A–I has been through a redesign PR + merged to `main`
2. ⬜ Buyer's login + register screens conform to `brand-kit/docs/crucible/auth-screens.md` exactly (Group A verifies this)
3. ⬜ `lib/components/README.md` exists and lists every component
4. ⬜ All 41+ tests pass on `main`
5. ⬜ `flutter analyze` introduces no new errors (pre-existing infos OK)
6. ⬜ `flutter build web --release` succeeds
7. ⬜ Manual smoke test on Chrome web: every screen reachable, visually coherent, no obviously broken layouts
8. ⬜ No `AppColors` references anywhere; no hardcoded `Color(0xFF...)` for screen-level colors (logo SVG colors don't count); no `TextStyle(fontFamily: ...)` in screen code
9. ⬜ All CTAs use plain transactional copy ("Buy now", "Add to basket", "Save changes", "Sign in", etc.)
10. ⬜ Two empty files (`profile_orders_view.dart`, `edit_address_view.dart`) resolved — either rebuilt or removed
11. ⬜ Brand kit's `auth-screens.md` is referenced from buyer's `CLAUDE.md` under "shared specs" so future sessions know about it

## Constraints

- **Don't touch state management.** Phase 2 finished the Riverpod migration. If a viewmodel needs a new field or method to support the redesigned screen, add it minimally, but no architecture changes.
- **Don't touch `flutter_stripe` / payments.** Payments cleanup is its own sub-project.
- **Don't touch the maps wiring.** FlutterMap + Nominatim are in place; redesign chrome around them, not the map widgets.
- **Don't rebuild things that work.** If a layout reads well, keep it; tighten spacing/typography only.
- **Components are extracted, not invented.** Three uses minimum before a widget moves to `lib/components/`.
- **Brand-kit submodule is private** — fresh clones need SSH access. Already documented in buyer's `CLAUDE.md`.
- Atomic commits, Conventional Commits prefixes, **no `Co-Authored-By` trailers**, push after every commit, one branch per group.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Scope creep — every redesign tempting to fix unrelated bugs | Strict: redesign-only PRs. Bugs found → file an issue or new fix branch. |
| Component extraction premature, leading to wrong abstractions | Three-uses rule. If a "ProductCard" appears in only 2 places, keep it inline. |
| Each group's PR conflicts with the next if too parallel | One group at a time, sequential merge. No parallel branches. |
| Auth design drifts as buyer/seller diverge over time | `brand-kit/docs/crucible/auth-screens.md` is the source of truth. Both apps' PRs must reference it in the description. |
| Time investment large (~30 screens) without intermediate ship | Each group's PR is independently shippable. After Group B (home), the app is already meaningfully better. |
| `flutter_svg` rendering issues recur for other brand-kit SVGs | Audit all brand-kit SVGs for `<style>` + class pattern; convert to inline fills as a small PR in this sub-project. |

## Tooling

- Visual verification on Chrome web (`flutter build web --release` + `python -m http.server`)
- Brand reference: open `brand-kit/docs/crucible/preview.html` in a second browser tab during redesign
- No Figma — design lives in `preview.html` + this spec + the auth-screens spec

## Out of scope (for sub-project 3.1)

- Seller app redesign — its own sub-project after this
- Landing pages (sub-projects 4 & 5)
- Payments cleanup
- Comprehensive test coverage
- Performance profiling
- Accessibility audit beyond what the existing theme + this redesign already encode
- Localization

## Next steps

After approval:

1. Invoke `writing-plans` skill to generate the implementation plan — one group at a time, with extracted components, with smoke-test checkpoints per group
2. Execute via subagent-driven development
3. Move on to sub-project 2 (seller mobile app rebrand) — which inherits this work via the auth-screens spec + brand kit

## References

- Brand kit: `personal-projects/unshelf/docs/crucible/` (submodule at `brand-kit/`)
- Brand identity: `brand-kit/docs/crucible/brand.md`
- Visual identity: `brand-kit/docs/crucible/design.md`
- Visual preview: `brand-kit/docs/crucible/preview.html`
- **Auth design spec (shared with seller):** `brand-kit/docs/crucible/auth-screens.md`
- Prior sub-project's spec: `docs/crucible/specs/2026-05-16-buyer-rebrand-design.md`
- Prior plan: `docs/crucible/plans/2026-05-16-buyer-rebrand-implementation.md`
