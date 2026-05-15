# CLAUDE.md — Unshelf Buyer App

Working notes for AI assistants editing this repo. Per user preference, every Unshelf repo gets a CLAUDE.md.

## What this is

The Unshelf buyer mobile app — Flutter, Firebase backend, Cebu-first near-expiry food marketplace. Sub-project 3 of 5 in the Unshelf rebrand decomposition.

See:
- Rebrand spec: `docs/crucible/specs/2026-05-16-buyer-rebrand-design.md`
- Implementation plan: `docs/crucible/plans/2026-05-16-buyer-rebrand-implementation.md`
- Brand kit (submodule): `brand-kit/docs/crucible/`

## After cloning

```bash
git submodule update --init --recursive
flutter pub get
```

If the brand kit submodule fails to clone, you need SSH access to `johnivanpuayap/unshelf-brand-kit` (private). Configure your GitHub SSH key.

## Locked decisions

- **Name + tagline:** Unshelf · Eat well. Waste less. (See `brand-kit/docs/crucible/brand.md`)
- **Palette:** Leaf & Honey. Primary green `#3F8E4A`. (See `brand-kit/docs/crucible/design.md`)
- **Typography:** DM Serif Display (display/headline/title) + DM Sans (body/label).
- **UI style:** Soft Editorial. Pill buttons. 14px card corners. No glassmorphism. No pure-white surfaces.
- **State management:** Riverpod 2.x with `@riverpod` codegen. (No more `provider` package after Phase 2.)
- **Maps:** flutter_map + OpenStreetMap tiles + Nominatim geocoding. No Google Maps after Phase 4.
- **Payments:** PayMongo. Stripe is being phased out in a later sub-project — leave it for now.
- **Main dashboard:** products. Not stats. Not gamification.

## Copy voice

- **Action buttons:** plain transactional only ("Buy now", "Add to basket", "Order", "Reserve", "Checkout", "View details"). NEVER "Rescue", "Save", "Snag", "Grab".
- **Headlines/taglines:** mission framing welcome.
- **State badges:** descriptive ("Rescued", "Expires in 2 days", "Saved from waste"), never imperative.

## Engineering rules

- Atomic commits with Conventional Commits prefixes.
- No `Co-Authored-By` trailers.
- Push frequently — after every commit.
- One branch per phase during rebrand work.
- Open PRs for phase merges via `gh pr create`; merge via `gh pr merge --squash`.
- Git identity: `johnivanpuayap@gmail.com` (personal).
- For new abstractions with non-obvious contracts, add a test. For broad coverage, wait for the test-coverage sub-project.
- Don't touch `flutter_stripe` / Stripe wiring until the payments sub-project.

## Common commands

```bash
flutter pub get                                                  # install
flutter analyze                                                  # lint
flutter test                                                     # all tests
dart run build_runner build --delete-conflicting-outputs        # regenerate Riverpod
flutter run                                                      # device run
```

## Memory references (for Claude Code sessions)

- `[[unshelf-rebrand]]` — overall rebrand context, decomposition, locked decisions
- `[[unshelf-copy-voice]]` — CTA copy rules
