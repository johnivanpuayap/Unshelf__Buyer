# Unshelf Buyer App — Rebrand Design Spec

> Date: 2026-05-16
> Status: Draft for review
> Sub-project: 3 of 5 in the Unshelf marketplace rebrand
> Repo: `personal-projects/unshelf-buyer/` · https://github.com/johnivanpuayap/unshelf-buyer

## Context

The Unshelf buyer app is an existing Flutter mobile app that lets users in Cebu shop near-expiry food from local stores. It has 27 view files, 13 viewmodels, Firebase as the backend, and recent restructuring that aligned its folder layout with the seller app.

**Current state (as of 2026-05-16, after pulling 30 commits):**

- `lib/` structure: `authentication/views/` (login + register), `views/` (27 screens), `viewmodels/` (13), `data/repositories/` (auth, product, storage, user + `firebase/` clients), `components/` (6 widgets), `services/` (chat + paymongo), `models/`, `utils/colors.dart` (centralized teal-based palette `#0AB68B` — pre-brand-kit).
- State management: `provider` package, `ChangeNotifierProvider` + `MultiProvider` in `main.dart`.
- Maps: `google_maps_flutter` AND `flutter_map` BOTH in pubspec — migration started, not finished. Goal: drop `google_maps_flutter`, finish on `flutter_map` + OSM tiles + Nominatim.
- Existing tests: 7 viewmodel tests under `test/viewmodels/` (address, dashboard, home, order_address, settings, user_profile, wallet) — preserve these through migration.
- Recent merges: regression testing waves, structural alignment with seller, viewmodel renames (`AddressViewmodel` → `AddressViewModel`), stock counter-widget test dropped, colors extracted to `lib/utils/colors.dart`.

This sub-project applies the **Unshelf brand kit** (sub-project 1, shipped 2026-05-15) to the buyer app and lands two foundational tech-stack migrations: state management to **Riverpod 2.x** and maps consolidation to **flutter_map + OSM + Nominatim** (removing `google_maps_flutter`).

Other work — payments cleanup (Stripe → PayMongo), additional test coverage, store submission polish — is deferred to dedicated sub-projects.

## Scope

**In:**
- Brand kit applied: colors, typography, logos, copy, Soft Editorial UI style across all screens
- State management migrated: `provider` package removed, all 13 viewmodels rewritten as Riverpod providers using `@riverpod` codegen
- Maps swapped: `google_maps_flutter` removed, replaced with `flutter_map` + OSM tiles + Nominatim geocoding

**Out:**
- Payments cleanup (Stripe → PayMongo consolidation)
- Full test coverage to release threshold
- New feature additions
- Screen rebuilds (medium retheme only — layouts stay unless clearly broken)
- Files/folders not tangled in the three scope items

## Concept summary

| Decision | Value |
|---|---|
| Repo | `personal-projects/unshelf-buyer/` (renamed from `Unshelf__Buyer` on 2026-05-16) |
| GitHub | https://github.com/johnivanpuayap/unshelf-buyer |
| Branch strategy | One branch per phase. Merge to `main` via PR at phase exit. |
| Brand kit consumption | Git submodule at `brand-kit/` |
| State management | Riverpod 2.x with `@riverpod` codegen |
| Maps | `flutter_map` + OSM tiles + Nominatim geocoding |
| Testing approach | Targeted: only where bug fix needs regression OR a new abstraction has non-obvious contract (e.g., Nominatim rate limiter) |
| Git identity | `johnivanpuayap@gmail.com` (already configured) |

Per Crucible: brand identity, visual identity, logo system, and tech stack are **inherited from the brand kit** (`brand-kit/docs/crucible/{brand,design,tech-stack}.md`). This spec does not redefine them.

## Phases

The work is sequenced into 4 phases. Each phase ends at a green state: app builds, runs, no console errors. Each is independently shippable.

### Phase 1 — Foundation

Branch: `phase/1-foundation`

Sets up the brand kit consumption and Riverpod plumbing without touching screen logic. Replaces the existing `lib/utils/colors.dart` palette with brand-kit-driven theme.

- Add `unshelf-brand-kit` as a Git submodule at `brand-kit/`
- Copy `brand-kit/tokens/tokens.dart` into `lib/theme/tokens.dart` (or symlink if filesystem supports)
- Build `lib/theme/unshelf_theme.dart` exposing `UnshelfTheme.light()` and `UnshelfTheme.dark()` — wraps `UnshelfTokens` constants into Flutter `ThemeData` (color scheme, text theme, button themes, input decoration, etc.)
- **Remove `lib/utils/colors.dart`** OR convert it to a deprecation shim that re-exports the closest brand tokens (decide based on how many files import it — grep first; if <5, delete and update call sites; if more, deprecate-then-remove in the screen retheme phase)
- Copy logo SVGs from `brand-kit/docs/crucible/logos/` into `assets/images/logos/`
- Wire DM Serif Display + DM Sans through the existing `google_fonts: ^6.2.1` package
- Add `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` (dev), `build_runner` (dev) to `pubspec.yaml`
- Wrap `runApp` in `ProviderScope(...)` — leave `MultiProvider` inside as a child so existing viewmodels keep working until phase 2 migrates them
- Add `CLAUDE.md` at repo root documenting locked decisions + submodule init step (per user preference)
- Open PR `phase/1-foundation` → `main` via `gh pr create` when exit criteria met

**Exit criteria:** `flutter pub get` succeeds, app builds, theme applied to MaterialApp, app boots without errors, the 7 existing viewmodel tests still pass under `flutter test`.

### Phase 2 — Riverpod migration

Migrates all 13 viewmodels in one focused sweep. One commit per viewmodel.

Viewmodels to migrate (current file → target provider):
- `home_view_model.dart` → `homeViewModelProvider`
- `dashboard_viewmodel.dart` → `dashboardProvider`
- `store_viewmodel.dart` → `storeProvider`
- `order_viewmodel.dart` → `orderProvider`
- `product_viewmodel.dart` → `productProvider`
- `listing_viewmodel.dart` → `listingProvider`
- `bundle_viewmodel.dart` → `bundleProvider`
- `address_viewmodel.dart` → `addressProvider`
- `order_address_viewmodel.dart` → `orderAddressProvider`
- `settings_viewmodel.dart` → `settingsProvider`
- `store_profile_viewmodel.dart` → `storeProfileProvider`
- `user_profile_viewmodel.dart` → `userProfileProvider`
- `wallet_viewmodel.dart` → `walletProvider`

Pattern: each former `ChangeNotifier` becomes a `Notifier<TState>` with a sealed `State` class (idle / loading / success / error). Consumers swap `Consumer<TViewModel>` → `Consumer(builder: (ctx, ref, _) => ...)` or `ConsumerWidget`. Run `dart run build_runner build --delete-conflicting-outputs` after each migration; commit generated files.

After all 13 are migrated:
- Remove `MultiProvider` wrapper from `main.dart`
- Remove `provider` package from `pubspec.yaml`
- Run `flutter pub get` to clean up
- Open PR `phase/2-riverpod-migration` → `main`

**Exit criteria:** zero `ChangeNotifierProvider` references, `provider` package not in pubspec, app builds + runs, all 7 ported tests + any new abstraction tests pass.

### Phase 3 — Screen retheme (medium polish)

Reviewed screen-by-screen. For each of the 30 view files:

- Replace hardcoded colors with `Theme.of(context).colorScheme.*` or direct `UnshelfTokens.*` references
- Replace hardcoded fonts with `Theme.of(context).textTheme.*`
- Normalize spacing to the 16/20/24px scale from `design.md`
- Swap CTAs to plain transactional copy ("Buy now", "Add to basket", "View details" — NEVER "Rescue", "Save", "Snag")
- Replace ad-hoc widgets with brand-kit-aligned versions when the existing one is poor; preserve layout otherwise
- Apply Soft Editorial principles: pill buttons, 14px card corners, two-layer shadows, no glassmorphism, no pure-white surfaces

One commit per screen (or per small related group, e.g. "auth screens"). Each commit should leave the app buildable.

**Exit criteria:** every screen reads visually as Unshelf — verified by manual smoke test of every navigation path. No hardcoded colors/fonts in screen-level code.

### Phase 4 — Maps swap

Replaces Google Maps with OSM + Nominatim across the buyer app.

- Remove `google_maps_flutter` from pubspec
- Add `flutter_map`, `latlong2`, `geolocator`
- Reimplement `lib/views/map_view.dart` using `FlutterMap` with `TileLayer` pointed at `https://tile.openstreetmap.org/{z}/{x}/{y}.png` (with proper attribution per OSM tile usage policy)
- Build `lib/services/nominatim_service.dart`:
  - `search(query)` for autocomplete / address search
  - `reverseGeocode(lat, lng)` for "what's here"
  - Internal rate limiter: max 1 request per second, with a small queue
  - Proper User-Agent header per Nominatim usage policy
- Migrate `store_address_view.dart` and any other map-using screen
- Remove Google Maps API key from `.env`/Info.plist/Android manifest

**Exit criteria:** zero references to `google_maps_flutter` in code or pubspec, map renders OSM tiles, search routes through Nominatim with rate limiting, OSM attribution visible on map screen.

## Testing approach

Per the deferred-tests decision, this sub-project's test work is constrained to:

1. **Preservation** — the 7 existing viewmodel tests in `test/viewmodels/` must remain green throughout. Port them to Riverpod testing patterns (`ProviderContainer` + `overrideWith`) in phase 2 as part of each viewmodel's migration commit.
2. **Bug fixes during the rebrand** — any bug found mid-flight gets a regression test before the fix.
3. **New abstractions with non-obvious contracts** — specifically:
   - `NominatimService.search()` and `reverseGeocode()` — rate limiter behavior (burst of 5 resolves in ~5 seconds, not <1)
   - `UnshelfTheme.light()` / `.dark()` — smoke test that key tokens (primary, surface, foreground) map to expected `UnshelfTokens.*` values

Broad widget/integration test coverage is the dedicated test-coverage sub-project, not this one.

## Acceptance criteria

The buyer rebrand sub-project is done when:

1. ⬜ `brand-kit/` Git submodule installed and tracked
2. ⬜ `lib/theme/unshelf_theme.dart` exposes `UnshelfTheme.light()` and `UnshelfTheme.dark()` driven by `UnshelfTokens`
3. ⬜ `lib/utils/colors.dart` retired (deleted or empty deprecation shim)
4. ⬜ `flutter pub get` succeeds; `provider` and `google_maps_flutter` removed; `flutter_riverpod` added
5. ⬜ App boots under `ProviderScope` with no runtime errors
6. ⬜ No hardcoded colors or fonts in screen-level code — grep `Color(0x` and `TextStyle(fontFamily:` returns zero hits in `lib/views/`, `lib/authentication/`, and `lib/components/`
7. ⬜ Logo + app icon + splash use Abundance Basket SVGs
8. ⬜ Zero `ChangeNotifierProvider` references remain
9. ⬜ All 13 viewmodels are Riverpod providers; the 7 existing viewmodel tests pass on Riverpod patterns
10. ⬜ Map view renders OSM tiles; address search routes through `NominatimService` with rate limiting + OSM attribution
11. ⬜ App runs end-to-end on Android emulator AND iOS simulator (manual smoke test of: login → browse → product detail → add to basket → checkout → order history → map)
12. ⬜ `CLAUDE.md` exists at repo root with locked decisions
13. ⬜ All four phase branches merged into `main` via PR

## Out of scope (for sub-project 3)

- Payments cleanup (Stripe references untouched; PayMongo service kept as-is)
- Comprehensive test coverage beyond the targeted tests above
- Performance optimization
- New features or screen additions
- Store-submission assets (real app icon export, splash screens at all device sizes, store screenshots, App Store listing copy)
- Push notification rewiring
- Localization / i18n
- Accessibility audit beyond what the brand kit already encodes (focus rings, AA contrast)

These each belong to follow-up sub-projects.

## Constraints

- Brand kit submodule is **private** (`johnivanpuayap/unshelf-brand-kit`). Cloning the buyer repo requires read access to the brand kit too. Acceptable since both are personal repos.
- Git identity for this repo: personal (`johnivanpuayap@gmail.com`) — already configured.
- No `Co-Authored-By` trailers in commits (per user preference).
- Atomic commits with Conventional Commits prefixes.
- One branch per phase: `phase/1-foundation`, `phase/2-riverpod-migration`, `phase/3-screen-retheme`, `phase/4-maps-swap`.
- Each task commits to the current phase branch and pushes after every commit (per user push-frequently preference).
- At phase exit (all phase tasks complete + manual smoke test passes), open a PR via `gh pr create` for that phase branch into `main`. Merge via `gh pr merge --squash` (or `--merge` if you'd prefer to preserve per-task commits — call it out before merging). Delete the branch after merge.
- Next phase branches off the freshly-merged `main`.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Provider → Riverpod migration breaks runtime state in screens we haven't retouched yet | Migrate one viewmodel at a time; smoke test the affected screens after each commit. Phase 2 happens before phase 3 retheme so the screens we touch in phase 3 already have stable Riverpod hooks. |
| Submodule access friction on fresh clones (or a future CI setup) | Document the `git submodule update --init --recursive` step in `CLAUDE.md`. The brand kit is private but readable by the same user — clones from any of their machines work with their SSH key. If/when CI is added later, configure a deploy key for the brand kit. |
| OSM Nominatim rate limit (1 req/sec) too restrictive for search-as-you-type | Implement client-side debounce (300ms) + queue. If still too slow during dogfood, fall back to Stadia Maps free tier (200k/month) — same code path, different tile + geocoder endpoints. Documented as a follow-up option. |
| Theme regression: a screen reads worse after retheme | Take before/after screenshots during phase 3; review each in turn. Easy to revert one screen's commit. |
| `flutter_stripe` still in main.dart causes confusion | Leave it for the payments-cleanup sub-project. Documented in CLAUDE.md so the next session knows. |

## Next steps

After this spec is approved:

1. Invoke `writing-plans` skill to generate the concrete task-by-task implementation plan for phases 1–4
2. Execute via subagent-driven development
3. Move on to sub-project 2 (seller mobile app rebrand) — same shape, can reuse most of this plan

## References

- Brand kit spec: `personal-projects/unshelf/docs/crucible/specs/2026-05-15-unshelf-brand-kit-design.md`
- Brand: `brand-kit/docs/crucible/brand.md`
- Design system: `brand-kit/docs/crucible/design.md`
- Tech stack: `brand-kit/docs/crucible/tech-stack.md`
- Logo USAGE: `brand-kit/docs/crucible/logos/USAGE.md`
- Visual preview: `brand-kit/docs/crucible/preview.html`
