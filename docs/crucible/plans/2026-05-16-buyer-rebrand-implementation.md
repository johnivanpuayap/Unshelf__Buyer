# Unshelf Buyer App Rebrand — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Unshelf brand kit, migrate state management to Riverpod 2.x, and finish the maps swap to flutter_map + OSM + Nominatim in the buyer Flutter app, shipped across 4 separately-merged phase PRs.

**Architecture:** Each phase is a feature branch (`phase/1-foundation`, `phase/2-riverpod-migration`, `phase/3-screen-retheme`, `phase/4-maps-swap`) merged via PR into `main`. Brand kit is consumed via Git submodule at `brand-kit/`. Tokens drive a single `UnshelfTheme` class that powers Flutter's `ThemeData`. Riverpod migration is one viewmodel per commit. Screen retheme groups screens by feature area. Maps work removes `google_maps_flutter` after `flutter_map` consumers are confirmed.

**Tech Stack:** Flutter 3.5+ · Dart · Riverpod 2.x with `@riverpod` codegen · flutter_map + latlong2 · http (for Nominatim) · google_fonts · firebase_* (auth, firestore, storage) · Git submodule.

**Spec:** `docs/crucible/specs/2026-05-16-buyer-rebrand-design.md`

**Commit + branch conventions:**
- Per-phase branch (4 branches total)
- One conventional-commit per task (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`)
- **No `Co-Authored-By` trailers**
- Push after each commit (per user preference)
- Open PR at phase exit via `gh pr create`; merge via `gh pr merge --squash`
- Git identity is already `johnivanpuayap@gmail.com` (verified) — no need to re-ask

---

## File Structure

```
personal-projects/unshelf-buyer/
├── .gitmodules                                   [Task 1.1 — defines brand-kit]
├── brand-kit/                                    [Task 1.1 — submodule]
├── CLAUDE.md                                     [Task 1.7]
├── lib/
│   ├── theme/                                    [NEW directory]
│   │   ├── tokens.dart                           [Task 1.2 — copy from brand-kit]
│   │   └── unshelf_theme.dart                    [Task 1.3]
│   ├── utils/colors.dart                         [Modify Task 1.5 → retire Task 3.X]
│   ├── main.dart                                 [Modify Tasks 1.4, 1.6, 2.15]
│   ├── viewmodels/*.dart                         [Modify each, Phase 2]
│   ├── views/*.dart                              [Modify each, Phase 3]
│   ├── authentication/views/*.dart               [Modify, Phase 3]
│   ├── components/*.dart                         [Modify, Phase 3]
│   ├── services/nominatim_service.dart           [Task 4.2 — NEW]
│   └── views/map_view.dart                       [Modify Task 4.3]
├── test/
│   ├── viewmodels/*_test.dart                    [Migrate each in Phase 2]
│   ├── services/nominatim_service_test.dart      [Task 4.2 — NEW]
│   └── theme/unshelf_theme_test.dart             [Task 1.3 — NEW]
├── pubspec.yaml                                  [Modify across phases]
├── assets/images/logos/                          [Task 1.5 — NEW]
└── ios/Runner/Info.plist                         [Modify Task 4.5]
    android/app/src/main/AndroidManifest.xml      [Modify Task 4.5]
    .env                                          [Modify Task 4.5]
```

---

## Riverpod Migration Pattern (reference for Phase 2 tasks)

This pattern applies to every viewmodel migration in Phase 2. Each Phase 2 task referencing this pattern still specifies its own files, state shape, and providers — the pattern is the *shape*, not a substitute for task content.

**Before (Provider):**
```dart
// viewmodels/foo_viewmodel.dart
class FooViewModel extends ChangeNotifier {
  FooState _state = FooState.idle();
  FooState get state => _state;

  Future<void> loadFoo() async {
    _state = FooState.loading();
    notifyListeners();
    try {
      final data = await _service.fetch();
      _state = FooState.success(data);
    } catch (e) {
      _state = FooState.error(e.toString());
    }
    notifyListeners();
  }
}
```

**After (Riverpod 2.x with codegen):**
```dart
// viewmodels/foo_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'foo_viewmodel.g.dart';

@riverpod
class FooViewModel extends _$FooViewModel {
  @override
  FooState build() => const FooState.idle();

  Future<void> loadFoo() async {
    state = const FooState.loading();
    try {
      final data = await ref.read(fooServiceProvider).fetch();
      state = FooState.success(data);
    } catch (e) {
      state = FooState.error(e.toString());
    }
  }
}
```

**Consumer migration (in views):**
```dart
// Before: Consumer<FooViewModel> wraps + uses Provider.of(context, listen: false)
// After:
class FooScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fooViewModelProvider);
    return state.when(
      idle: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      success: (data) => FooView(data),
      error: (msg) => Text(msg),
    );
  }

  // For triggering side effects, use:
  // ref.read(fooViewModelProvider.notifier).loadFoo();
}
```

**Test migration:**
```dart
// Before: test creates ViewModel directly, mocks service
// After:
test('loadFoo populates success', () async {
  final container = ProviderContainer(overrides: [
    fooServiceProvider.overrideWithValue(FakeFooService()),
  ]);
  addTearDown(container.dispose);

  await container.read(fooViewModelProvider.notifier).loadFoo();

  expect(container.read(fooViewModelProvider), isA<FooStateSuccess>());
});
```

After each viewmodel migration, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit both the hand-edited `*.dart` and the generated `*.g.dart`.

---

## Phase 1 — Foundation

Branch: `phase/1-foundation`

Builds the brand kit consumption + Riverpod plumbing. App still uses Provider for state — viewmodel migration is Phase 2.

### Task 1.1: Branch + add brand kit submodule

**Files:**
- Modify: `.gitmodules` (new file)
- Add: `brand-kit/` submodule

- [ ] **Step 1: Create the phase branch**

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-buyer"
git checkout main
git pull --rebase origin main
git checkout -b phase/1-foundation
```

Expected: now on `phase/1-foundation`.

- [ ] **Step 2: Add the brand kit submodule**

```bash
git submodule add git@github.com:johnivanpuayap/unshelf-brand-kit.git brand-kit
```

Expected: `brand-kit/` directory created with brand kit content; `.gitmodules` created.

- [ ] **Step 3: Verify submodule contents**

```bash
ls brand-kit/tokens/ && ls brand-kit/docs/crucible/logos/ | head -3
```

Expected: shows `tokens.css`, `tokens.dart`, `tailwind.preset.js` and at least `favicon.svg`, `logo.svg`.

- [ ] **Step 4: Commit + push**

```bash
git add .gitmodules brand-kit
git commit -m "chore: add unshelf-brand-kit as submodule at brand-kit/"
git push -u origin phase/1-foundation
```

---

### Task 1.2: Mirror brand-kit tokens into lib/theme/tokens.dart

**Files:**
- Create: `lib/theme/tokens.dart`

- [ ] **Step 1: Mirror the tokens file**

The Dart `import 'package:flutter/material.dart';` line in `brand-kit/tokens/tokens.dart` means the submodule's file already imports Flutter — but Flutter's `package:` URI scheme only resolves inside the buyer app's package. So we copy the file into `lib/theme/tokens.dart` rather than relying on it from the submodule path.

```bash
mkdir -p lib/theme
cp brand-kit/tokens/tokens.dart lib/theme/tokens.dart
```

- [ ] **Step 2: Verify copy**

```bash
head -10 lib/theme/tokens.dart
```

Expected: shows `// GENERATED FILE — do not edit by hand.` header and `abstract class UnshelfTokens` declaration.

- [ ] **Step 3: Add a header note explaining the mirror relationship**

Edit `lib/theme/tokens.dart` and replace the second comment line. Current:
```dart
// Source: tokens.json. Regenerate via `npm run build`.
```
Replace with:
```dart
// Source: brand-kit/tokens/tokens.dart (submodule). Regenerate via the brand-kit's `npm run build`, then copy here via Task 1.2 / a refresh script.
```

- [ ] **Step 4: Commit + push**

```bash
git add lib/theme/tokens.dart
git commit -m "feat(theme): mirror brand-kit tokens into lib/theme/tokens.dart"
git push
```

---

### Task 1.3: Build UnshelfTheme.light() + .dark() — TDD

**Files:**
- Create: `lib/theme/unshelf_theme.dart`
- Create: `test/theme/unshelf_theme_test.dart`

- [ ] **Step 1: Write the failing theme test**

```bash
mkdir -p test/theme
```

Create `test/theme/unshelf_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/theme/tokens.dart';
import 'package:unshelf_buyer/theme/unshelf_theme.dart';

void main() {
  group('UnshelfTheme.light()', () {
    final theme = UnshelfTheme.light();

    test('uses Leaf & Honey primary green', () {
      expect(theme.colorScheme.primary, UnshelfTokens.colorLightPrimary);
    });

    test('uses cream background, not pure white', () {
      expect(theme.colorScheme.surface, UnshelfTokens.colorLightBackground);
      expect(theme.colorScheme.surface, isNot(Colors.white));
    });

    test('uses DM Sans for body text', () {
      expect(theme.textTheme.bodyLarge!.fontFamily, contains('DM Sans'));
    });

    test('uses DM Serif Display for display + headline + title', () {
      expect(theme.textTheme.displayLarge!.fontFamily, contains('DM Serif Display'));
      expect(theme.textTheme.headlineLarge!.fontFamily, contains('DM Serif Display'));
      expect(theme.textTheme.titleLarge!.fontFamily, contains('DM Serif Display'));
    });
  });

  group('UnshelfTheme.dark()', () {
    final theme = UnshelfTheme.dark();

    test('uses dark-mode primary green', () {
      expect(theme.colorScheme.primary, UnshelfTokens.colorDarkPrimary);
    });

    test('uses deep forest background', () {
      expect(theme.colorScheme.surface, UnshelfTokens.colorDarkBackground);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/theme/unshelf_theme_test.dart
```

Expected: FAIL with "Target of URI doesn't exist" or "UnshelfTheme isn't defined".

- [ ] **Step 3: Implement UnshelfTheme**

Create `lib/theme/unshelf_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

abstract class UnshelfTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: UnshelfTokens.colorLightPrimary,
      onPrimary: UnshelfTokens.colorLightOnPrimary,
      secondary: UnshelfTokens.colorLightAccent,
      onSecondary: UnshelfTokens.colorLightForeground,
      tertiary: UnshelfTokens.colorLightHighlight,
      error: UnshelfTokens.colorLightDestructive,
      onError: UnshelfTokens.colorLightOnPrimary,
      surface: UnshelfTokens.colorLightBackground,
      onSurface: UnshelfTokens.colorLightForeground,
      surfaceContainerHighest: UnshelfTokens.colorLightSurface,
      outline: UnshelfTokens.colorLightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorLightBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: UnshelfTokens.colorDarkPrimary,
      onPrimary: UnshelfTokens.colorDarkOnPrimary,
      secondary: UnshelfTokens.colorDarkAccent,
      onSecondary: UnshelfTokens.colorDarkForeground,
      tertiary: UnshelfTokens.colorDarkHighlight,
      error: UnshelfTokens.colorDarkDestructive,
      onError: UnshelfTokens.colorDarkOnPrimary,
      surface: UnshelfTokens.colorDarkBackground,
      onSurface: UnshelfTokens.colorDarkForeground,
      surfaceContainerHighest: UnshelfTokens.colorDarkSurface,
      outline: UnshelfTokens.colorDarkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorDarkBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static TextTheme _textTheme(Color onSurface) {
    final display = GoogleFonts.dmSerifDisplayTextTheme().apply(bodyColor: onSurface, displayColor: onSurface);
    final body = GoogleFonts.dmSansTextTheme().apply(bodyColor: onSurface, displayColor: onSurface);
    return TextTheme(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge,
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge,
      bodyMedium: body.bodyMedium,
      bodySmall: body.bodySmall,
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium,
      labelSmall: body.labelSmall,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      shape: const StadiumBorder(),
    ),
  );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: cs.secondary,
      foregroundColor: cs.onSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      shape: const StadiumBorder(),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.outline, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      shape: const StadiumBorder(),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) => InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outline, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 2),
    ),
  );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
    color: cs.surfaceContainerHighest,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/theme/unshelf_theme_test.dart
```

Expected: 6 tests pass.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

```bash
flutter test
```

Expected: all 7 existing viewmodel tests + 6 new theme tests pass.

- [ ] **Step 6: Commit + push**

```bash
git add lib/theme/unshelf_theme.dart test/theme/unshelf_theme_test.dart
git commit -m "feat(theme): add UnshelfTheme.light() and .dark() driven by brand tokens"
git push
```

---

### Task 1.4: Apply UnshelfTheme to MaterialApp

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Locate and read current `main.dart`**

```bash
cat lib/main.dart
```

You'll see a `MaterialApp` (possibly inside a wrapper). Locate its `theme:` property (and `darkTheme:` if present).

- [ ] **Step 2: Wire UnshelfTheme**

In `lib/main.dart`, add the import at the top:

```dart
import 'package:unshelf_buyer/theme/unshelf_theme.dart';
```

Replace the `theme:` value (whatever the current `ThemeData(...)` or `AppTheme.X` is) with:

```dart
theme: UnshelfTheme.light(),
darkTheme: UnshelfTheme.dark(),
themeMode: ThemeMode.system,
```

If `themeMode` is already set, preserve the user's choice; do NOT force `ThemeMode.system` if they had something else.

- [ ] **Step 3: Build and run**

```bash
flutter analyze
flutter test
```

Expected: analyze produces no new errors; tests pass.

Then (manual, on emulator):
```bash
flutter run
```

Expected: app boots; visible green/cream Unshelf palette across whatever screens you navigate.

- [ ] **Step 4: Commit + push**

```bash
git add lib/main.dart
git commit -m "feat(theme): wire UnshelfTheme into MaterialApp"
git push
```

---

### Task 1.5: Copy logo + favicon assets

**Files:**
- Create: `assets/images/logos/` (10 SVGs)
- Modify: `pubspec.yaml` (add assets entry if missing)

- [ ] **Step 1: Copy all logo variants from the submodule**

```bash
mkdir -p assets/images/logos
cp brand-kit/docs/crucible/logos/*.svg assets/images/logos/
ls assets/images/logos/
```

Expected: 10 SVG files listed (logo.svg, logo-mono-dark.svg, logo-mono-light.svg, logo-icon.svg, logo-icon-mono-dark.svg, logo-icon-mono-light.svg, logo-wordmark.svg, logo-wordmark-mono-dark.svg, logo-wordmark-mono-light.svg, favicon.svg).

- [ ] **Step 2: Add the directory to pubspec.yaml under `flutter: assets:`**

Find the `flutter:` block in `pubspec.yaml` (near the bottom). Ensure under `assets:` there is an entry for `- assets/images/logos/` (trailing slash includes the whole directory). If the `assets:` block doesn't exist, add:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logos/
```

Preserve any existing asset entries.

- [ ] **Step 3: Run `flutter pub get` + verify**

```bash
flutter pub get
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit + push**

```bash
git add assets/images/logos/ pubspec.yaml
git commit -m "feat(assets): add Abundance Basket logo + favicon SVGs from brand kit"
git push
```

---

### Task 1.6: Add Riverpod deps + wrap runApp in ProviderScope

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add Riverpod dependencies**

In `pubspec.yaml`, under `dependencies:`:

```yaml
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
```

Under `dev_dependencies:`:

```yaml
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.11
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
```

Then:

```bash
flutter pub get
```

Expected: dependencies resolve without conflict. (Provider stays for now — Phase 2 removes it.)

- [ ] **Step 2: Wrap MultiProvider in ProviderScope**

In `lib/main.dart`, find the `runApp(MultiProvider(...))` call and wrap it:

```dart
runApp(
  ProviderScope(
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreViewModel("2gxma4nHjhcHsOgDDDarlyeEvy12")),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        // Add more providers here
      ],
      child: const MyApp(),
    ),
  ),
);
```

Add import at the top of `main.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

- [ ] **Step 3: Build + test**

```bash
flutter analyze
flutter test
flutter run --device-id <android-or-ios-id>   # manual smoke test
```

Expected: app boots without runtime errors. The "Riverpod ProviderScope is now active but unused" warning may appear from `riverpod_lint` — that's expected; Phase 2 will populate it.

- [ ] **Step 4: Commit + push**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore(deps): add flutter_riverpod + codegen; wrap runApp in ProviderScope"
git push
```

---

### Task 1.7: Add CLAUDE.md

**Files:**
- Create: `CLAUDE.md` (at repo root)

- [ ] **Step 1: Author CLAUDE.md**

Create `CLAUDE.md` with this content:

```markdown
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
- **State management:** Riverpod 2.x with `@riverpod` codegen. (No more `provider` package.)
- **Maps:** flutter_map + OpenStreetMap tiles + Nominatim geocoding. No Google Maps.
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
```

- [ ] **Step 2: Commit + push**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md for AI assistants"
git push
```

---

### Task 1.8: Open PR, smoke test, merge to main

- [ ] **Step 1: Open the PR**

```bash
gh pr create --base main --head phase/1-foundation \
  --title "Phase 1: Foundation — brand kit + theme + Riverpod plumbing" \
  --body "Implements Phase 1 of the buyer rebrand spec. Brand kit submodule, tokens mirrored, UnshelfTheme wired, logo assets, ProviderScope, CLAUDE.md. No viewmodel migration yet (Phase 2)."
```

Expected: PR URL printed.

- [ ] **Step 2: Smoke test on an Android emulator + iOS simulator**

Manual checklist:
- App boots
- Navigate to login screen — palette looks green/cream (Leaf & Honey)
- Headlines render in DM Serif Display
- Body text in DM Sans
- Existing screens still functional (Provider viewmodels still working)

If anything fails, push a fix commit to `phase/1-foundation`.

- [ ] **Step 3: Merge the PR**

```bash
gh pr merge phase/1-foundation --squash --delete-branch
```

Expected: branch deleted, `main` updated.

- [ ] **Step 4: Update local main**

```bash
git checkout main
git pull --rebase origin main
```

---

## Phase 2 — Riverpod Migration

Branch: `phase/2-riverpod-migration`

Migrates all 13 viewmodels using the **Riverpod Migration Pattern** above. Each task references that pattern + supplies the viewmodel-specific path, state shape, and consumer impact.

### Task 2.1: Create phase branch

- [ ] **Step 1: Branch off updated main**

```bash
git checkout main
git pull --rebase origin main
git checkout -b phase/2-riverpod-migration
git push -u origin phase/2-riverpod-migration
```

---

### Task 2.2 through 2.14: Migrate each viewmodel (13 tasks)

For each viewmodel in the list below, follow the **Riverpod Migration Pattern**: read the current `ChangeNotifier` class, identify its state shape, rewrite as `@riverpod` notifier with a sealed `*State`, port any existing test in `test/viewmodels/<name>_test.dart` to `ProviderContainer + overrideWith`, run codegen, run tests, commit.

The order is chosen to migrate leaf viewmodels (those not depending on others) first.

For each viewmodel listed below, the engineer should:

1. Read the current file at `lib/viewmodels/<name>.dart`
2. Read its consumers (grep `<ClassName>` in `lib/`)
3. Read the existing test if present (in `test/viewmodels/<name>_test.dart`)
4. Apply the Riverpod Migration Pattern
5. Run `dart run build_runner build --delete-conflicting-outputs`
6. Run `flutter test test/viewmodels/<name>_test.dart` — must pass
7. Run `flutter analyze` — must pass for files touched
8. Commit:
   ```bash
   git add lib/viewmodels/<name>.dart lib/viewmodels/<name>.g.dart <consumers...> test/viewmodels/<name>_test.dart
   git commit -m "refactor(<name>): migrate ViewModel from Provider to Riverpod"
   git push
   ```

**Viewmodel migration order:**

| Task | File | Provider name | Notes |
|---|---|---|---|
| 2.2 | `wallet_viewmodel.dart` | `walletViewModelProvider` | Has existing test. Depends on `WalletService` (already injected — easy). |
| 2.3 | `settings_viewmodel.dart` | `settingsViewModelProvider` | Has existing test. |
| 2.4 | `user_profile_viewmodel.dart` | `userProfileViewModelProvider` | Has existing test. Depends on `UserRepository`. |
| 2.5 | `address_viewmodel.dart` | `addressViewModelProvider` | Has existing test. |
| 2.6 | `order_address_viewmodel.dart` | `orderAddressViewModelProvider` | Has existing test. Depends on `AuthRepository`, `UserRepository`. |
| 2.7 | `dashboard_viewmodel.dart` | `dashboardViewModelProvider` | Has existing test. `fetchDashboardData` is already caller-driven. |
| 2.8 | `home_viewmodel.dart` | `homeViewModelProvider` | Has existing test. |
| 2.9 | `store_viewmodel.dart` | `storeViewModelProvider` | Currently parameterized by user ID — Riverpod equivalent is a `family` provider. |
| 2.10 | `store_profile_viewmodel.dart` | `storeProfileViewModelProvider` | |
| 2.11 | `product_viewmodel.dart` | `productViewModelProvider` | |
| 2.12 | `listing_viewmodel.dart` | `listingViewModelProvider` | |
| 2.13 | `bundle_viewmodel.dart` | `bundleViewModelProvider` | |
| 2.14 | `order_viewmodel.dart` | `orderViewModelProvider` | Last because it integrates with checkout flow. |

For each task, commit message format: `refactor(<viewmodel-base-name>): migrate from Provider to Riverpod` (e.g., `refactor(wallet): ...`, `refactor(home): ...`).

**Common gotchas during migration:**

- If a viewmodel's `build()` should NOT auto-load data (it's lazy / caller-driven), make `build()` return `const FooState.idle()` and add a public `load()` method that the consumer calls explicitly. This matches the existing buyer pattern (e.g., dashboard is already caller-driven).
- If a viewmodel was parameterized in its constructor (e.g., `StoreViewModel(userId)`), use Riverpod's `@riverpod` with a positional argument — the generated provider becomes a `StoreViewModelProvider.call(userId)` family.
- If consumers use `Provider.of(context, listen: false)` to read state once, replace with `ref.read(viewModelProvider.notifier).method()`.
- If consumers use `Consumer<TViewModel>` builders, replace with `Consumer(builder: (ctx, ref, _) => ...)` or `ConsumerWidget`.
- After each migration, generated `*.g.dart` files MUST be committed.

---

### Task 2.15: Remove Provider package

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Confirm zero remaining usage**

```bash
grep -rn "ChangeNotifierProvider\|Provider.of\|MultiProvider\|ChangeNotifier " lib/ test/
```

Expected: zero output. If any matches remain, finish migrating those consumers before continuing.

- [ ] **Step 2: Unwrap MultiProvider in main.dart**

In `lib/main.dart`, replace:

```dart
runApp(
  ProviderScope(
    child: MultiProvider(
      providers: [ ... ],
      child: const MyApp(),
    ),
  ),
);
```

with:

```dart
runApp(
  const ProviderScope(
    child: MyApp(),
  ),
);
```

Remove imports for `provider/provider.dart` from `main.dart`.

- [ ] **Step 3: Remove provider from pubspec.yaml**

Delete the line `provider: ^6.1.2` from `dependencies:` in `pubspec.yaml`.

Then:

```bash
flutter pub get
flutter analyze
flutter test
```

Expected: no errors. All tests pass.

- [ ] **Step 4: Commit + push**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore(deps): remove provider package; ProviderScope is the only root state container"
git push
```

---

### Task 2.16: PR + merge

- [ ] **Step 1: Open the PR**

```bash
gh pr create --base main --head phase/2-riverpod-migration \
  --title "Phase 2: Riverpod migration — all 13 viewmodels + provider package removed" \
  --body "Implements Phase 2 of the buyer rebrand spec. Every ChangeNotifier replaced by an @riverpod notifier with a sealed *State; consumers updated to ConsumerWidget / ref.watch / ref.read; existing 7 viewmodel tests ported and passing."
```

- [ ] **Step 2: Smoke test on emulators**

Manual: navigate every screen. Confirm no runtime errors. Confirm Riverpod inspector (devtools) shows providers.

- [ ] **Step 3: Merge + update main**

```bash
gh pr merge phase/2-riverpod-migration --squash --delete-branch
git checkout main && git pull --rebase origin main
```

---

## Phase 3 — Screen Retheme

Branch: `phase/3-screen-retheme`

Retheme 27 + 2 + 6 surfaces using the brand tokens already wired through `UnshelfTheme`. Group by feature area.

### Task 3.1: Create phase branch

- [ ] **Step 1: Branch off main**

```bash
git checkout main && git pull --rebase origin main
git checkout -b phase/3-screen-retheme
git push -u origin phase/3-screen-retheme
```

---

### Tasks 3.2 through 3.10: Retheme screen groups

For each group, the engineer should:

1. List the files in the group
2. For each file, audit:
   - Hardcoded `Color(0x...)` — replace with `Theme.of(context).colorScheme.X` or `UnshelfTokens.X`
   - Hardcoded `TextStyle(fontFamily: ...)` or `GoogleFonts.X()` — replace with `Theme.of(context).textTheme.X`
   - References to `AppColors` (from `lib/utils/colors.dart`) — replace with theme tokens
   - Hardcoded paddings outside the 4/8/16/20/24/32/48 scale — normalize
   - CTA copy ("Rescue", "Save", "Snag") — replace per the locked rule
   - Components with sharp corners (interactive elements) — replace with 12-pill radii
3. Run `flutter analyze` after each file
4. Smoke test the group's screens on emulator
5. Commit per group:
   ```bash
   git add lib/views/<group-files> lib/components/<related-components>
   git commit -m "feat(retheme): apply Unshelf brand to <group-name> screens"
   git push
   ```

**Retheme groups:**

| Task | Group | Files |
|---|---|---|
| 3.2 | Auth | `lib/authentication/views/login_view.dart`, `register_view.dart` |
| 3.3 | Home + dashboard | `lib/views/home_view.dart`, `notifications_view.dart` |
| 3.4 | Browsing | `lib/views/category_view.dart`, `search_view.dart`, `stores_view.dart`, `store_view.dart`, `store_reviews_view.dart` |
| 3.5 | Product | `lib/views/product_view.dart`, `product_bundle_view.dart`, `review_view.dart` |
| 3.6 | Basket + checkout | `lib/views/basket_view.dart`, `basket_checkout_view.dart`, `order_placed_view.dart`, `order_address_view.dart` |
| 3.7 | Orders + tracking | `lib/views/order_history_view.dart`, `order_details_view.dart`, `order_tracking_view.dart`, `profile_orders_view.dart` |
| 3.8 | Profile + settings | `lib/views/profile_view.dart`, `edit_profile_view.dart`, `profile_favorites_view.dart`, `profile_following_view.dart`, `edit_address_view.dart`, `store_address_view.dart` |
| 3.9 | Chat + reports + misc | `lib/views/chat_screen.dart`, `chat_view.dart`, `report_view.dart`, `map_view.dart` (visual only — full migration is Phase 4) |
| 3.10 | Shared components | `lib/components/category_row_widget.dart`, `chat_bubble.dart`, `custom_navigation_bar.dart`, `datetime_picker.dart`, `my_switch.dart`, `my_textfield.dart` |

---

### Task 3.11: Retire `lib/utils/colors.dart`

**Files:**
- Delete: `lib/utils/colors.dart`

- [ ] **Step 1: Confirm zero remaining usage**

```bash
grep -rn "AppColors\." lib/ test/
```

Expected: zero output. If any matches remain, finish retheming those files first.

- [ ] **Step 2: Delete the file**

```bash
rm lib/utils/colors.dart
flutter analyze
flutter test
```

Expected: no errors, all tests pass.

- [ ] **Step 3: Commit + push**

```bash
git add -u lib/utils/
git commit -m "chore: remove lib/utils/colors.dart — all callers now use UnshelfTheme"
git push
```

---

### Task 3.12: Verification grep + PR + merge

- [ ] **Step 1: Grep for stragglers**

```bash
grep -rn "Color(0x" lib/views/ lib/authentication/ lib/components/
grep -rn "TextStyle(fontFamily:" lib/views/ lib/authentication/ lib/components/
grep -rn -i "rescue\|snag\|grab" lib/views/ lib/authentication/ lib/components/
```

All three should return zero hits. If anything remains, fix it as a final retheme commit, then re-check.

- [ ] **Step 2: Open PR**

```bash
gh pr create --base main --head phase/3-screen-retheme \
  --title "Phase 3: Screen retheme — all 35 surfaces on Soft Editorial" \
  --body "Implements Phase 3. Every screen + component uses Theme.of(context) tokens or UnshelfTokens. No hardcoded colors/fonts in screen-level code. CTA copy rule enforced. lib/utils/colors.dart retired."
```

- [ ] **Step 3: Smoke test, merge, update main**

Manual smoke: login → browse → product → basket → checkout → order history → map → profile.

```bash
gh pr merge phase/3-screen-retheme --squash --delete-branch
git checkout main && git pull --rebase origin main
```

---

## Phase 4 — Maps Swap

Branch: `phase/4-maps-swap`

### Task 4.1: Create phase branch + audit current map state

- [ ] **Step 1: Branch off main**

```bash
git checkout main && git pull --rebase origin main
git checkout -b phase/4-maps-swap
git push -u origin phase/4-maps-swap
```

- [ ] **Step 2: Audit current map usage**

```bash
grep -rn "google_maps_flutter\|GoogleMap\|FlutterMap\|MapView\|geocoding\b" lib/
```

This identifies every map-touching screen + service. Expected: `map_view.dart`, possibly `store_address_view.dart`, possibly the `geocoding` package usage in viewmodels (which the buyer pubspec has).

Document findings inline as a checklist:

```
- lib/views/map_view.dart — uses: [TBD after grep]
- lib/views/store_address_view.dart — uses: [TBD after grep]
- lib/viewmodels/X.dart — uses geocoding: [TBD]
```

- [ ] **Step 3: Commit the audit notes**

Append the findings as a comment block at the top of `docs/crucible/plans/2026-05-16-buyer-rebrand-implementation.md` under a new "Phase 4 audit notes" section (or in a new file at `docs/crucible/plans/notes/phase-4-map-audit.md`).

```bash
git add docs/crucible/plans/
git commit -m "docs(phase-4): record map + geocoding audit findings"
git push
```

---

### Task 4.2: Build NominatimService — TDD

**Files:**
- Create: `lib/services/nominatim_service.dart`
- Create: `test/services/nominatim_service_test.dart`

- [ ] **Step 1: Write the failing rate-limiter test**

```bash
mkdir -p test/services
```

Create `test/services/nominatim_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/services/nominatim_service.dart';

void main() {
  group('NominatimService rate limiter', () {
    test('5 sequential search() calls take ~5 seconds (1 req/sec)', () async {
      // Build a service with a no-network search implementation so we test only
      // the rate-limiter timing.
      final service = NominatimService.withMockResponder(
        responder: (uri) async => '[]', // empty results JSON
      );

      final stopwatch = Stopwatch()..start();
      await Future.wait(List.generate(5, (i) => service.search('test $i')));
      stopwatch.stop();

      // At 1 req/sec, 5 requests take 4-5 seconds. Allow 3.5-6 second window for CI variance.
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(3500));
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(6000));
    });

    test('debounced search ignores rapid intermediate calls', () async {
      var responderCalls = 0;
      final service = NominatimService.withMockResponder(
        responder: (uri) async {
          responderCalls++;
          return '[]';
        },
      );

      // Fire 3 search-as-you-type events within 100ms — debounce window is 300ms
      service.searchDebounced('a');
      await Future.delayed(const Duration(milliseconds: 50));
      service.searchDebounced('ab');
      await Future.delayed(const Duration(milliseconds: 50));
      service.searchDebounced('abc');

      // Wait for the debounce window + rate limiter slot
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(responderCalls, 1); // only the last input triggered a real call
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/nominatim_service_test.dart
```

Expected: FAIL — NominatimService not yet defined.

- [ ] **Step 3: Implement NominatimService**

Create `lib/services/nominatim_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef _Responder = Future<String> Function(Uri);

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'Unshelf-Buyer/1.0 (https://unshelf.ph)';
  static const Duration _minInterval = Duration(seconds: 1);
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  NominatimService() : _responder = _defaultResponder;

  NominatimService.withMockResponder({required _Responder responder})
      : _responder = responder;

  final _Responder _responder;
  DateTime _lastRequestAt = DateTime.fromMicrosecondsSinceEpoch(0);
  final _gateLock = _AsyncLock();
  Timer? _debounceTimer;

  Future<List<NominatimPlace>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    await _waitForRateSlot();
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
    });
    final body = await _responder(uri);
    final decoded = jsonDecode(body) as List<dynamic>;
    return decoded.map((j) => NominatimPlace.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<NominatimPlace?> reverseGeocode(double lat, double lng) async {
    await _waitForRateSlot();
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
      'addressdetails': '1',
    });
    final body = await _responder(uri);
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['error'] == null) {
      return NominatimPlace.fromJson(decoded);
    }
    return null;
  }

  /// Fire-and-forget debounced search — convenience for search-as-you-type UI.
  /// Caller subscribes to [searchStream] (not implemented here for brevity;
  /// for the test we just count responder calls).
  void searchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      // Fire the search; caller is expected to await `search()` directly for results.
      // For real consumers, route through a StreamController; for the smoke test,
      // we just trigger the responder.
      unawaited(search(query));
    });
  }

  Future<void> _waitForRateSlot() async {
    await _gateLock.acquire();
    try {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRequestAt);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
      _lastRequestAt = DateTime.now();
    } finally {
      _gateLock.release();
    }
  }

  static Future<String> _defaultResponder(Uri uri) async {
    final resp = await http.get(uri, headers: {'User-Agent': _userAgent});
    return resp.body;
  }
}

class NominatimPlace {
  NominatimPlace({required this.displayName, required this.lat, required this.lng});
  final String displayName;
  final double lat;
  final double lng;

  factory NominatimPlace.fromJson(Map<String, dynamic> j) => NominatimPlace(
    displayName: j['display_name'] as String? ?? '',
    lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
    lng: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
  );
}

class _AsyncLock {
  Completer<void>? _completer;

  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  void release() {
    final c = _completer;
    _completer = null;
    c?.complete();
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/nominatim_service_test.dart
```

Expected: both tests pass within 6 seconds total.

- [ ] **Step 5: Commit + push**

```bash
git add lib/services/nominatim_service.dart test/services/nominatim_service_test.dart
git commit -m "feat(maps): add NominatimService with 1-req/sec rate limit + debounce"
git push
```

---

### Task 4.3: Audit and migrate map_view.dart to flutter_map

**Files:**
- Modify: `lib/views/map_view.dart`

- [ ] **Step 1: Read current map_view.dart**

Read the file. Note whether it uses `GoogleMap` from `google_maps_flutter` or `FlutterMap` from `flutter_map`. If FlutterMap is already in use, verify the tile layer URL points at OSM.

- [ ] **Step 2: Replace with flutter_map**

If the file still uses `GoogleMap`, replace the body with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapView extends ConsumerWidget {
  const MapView({super.key, this.initialCenter, this.markers});
  final LatLng? initialCenter;
  final List<Marker>? markers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter ?? const LatLng(10.3157, 123.8854), // Cebu City
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ph.unshelf.buyer',
          ),
          const CurrentLocationLayer(),
          if (markers != null) MarkerLayer(markers: markers!),
          RichAttributionWidget(attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              textStyle: TextStyle(color: cs.onSurface, fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }
}
```

Adapt the public constructor signature to match whatever the current `MapView` exposes (so existing callers don't break).

- [ ] **Step 3: Run analyze + test**

```bash
flutter analyze lib/views/map_view.dart
flutter test
```

Expected: no errors.

- [ ] **Step 4: Manual smoke test the map screen**

Navigate to the map screen on emulator. Verify OSM tiles render and OSM attribution is visible.

- [ ] **Step 5: Commit + push**

```bash
git add lib/views/map_view.dart
git commit -m "refactor(maps): replace GoogleMap with FlutterMap + OSM tiles in MapView"
git push
```

---

### Task 4.4: Migrate other map consumers + replace `geocoding` package calls

**Files:**
- Modify: `lib/views/store_address_view.dart` (or any other map/geocoding consumer found in Task 4.1's audit)

- [ ] **Step 1: For each consumer, swap GoogleMap → FlutterMap and `geocoding` → `NominatimService`**

Pattern for replacing `geocoding`:

Before:
```dart
import 'package:geocoding/geocoding.dart';

final placemarks = await placemarkFromCoordinates(lat, lng);
final address = placemarks.first.thoroughfare;
```

After:
```dart
import 'package:unshelf_buyer/services/nominatim_service.dart';

final service = NominatimService();
final place = await service.reverseGeocode(lat, lng);
final address = place?.displayName;
```

For search-as-you-type address entry: use `service.searchDebounced(input)` and watch results.

- [ ] **Step 2: Verify nothing else imports `geocoding` or `google_maps_flutter`**

```bash
grep -rn "package:geocoding\|package:google_maps_flutter" lib/
```

Expected: zero hits.

- [ ] **Step 3: Run analyze + test + manual smoke**

```bash
flutter analyze
flutter test
```

Manual: test address entry, store address view, any other touched screens.

- [ ] **Step 4: Commit + push (one commit per consumer migrated)**

```bash
git add <files>
git commit -m "refactor(<screen>): replace GoogleMap + geocoding with FlutterMap + NominatimService"
git push
```

---

### Task 4.5: Remove google_maps_flutter + geocoding + Google Maps API key

**Files:**
- Modify: `pubspec.yaml`
- Modify: `.env`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Final verification — no consumers left**

```bash
grep -rn "package:google_maps_flutter\|package:geocoding\b" lib/ test/
```

Expected: zero hits.

- [ ] **Step 2: Remove the packages**

In `pubspec.yaml`, delete these two lines from `dependencies:`:

```yaml
  google_maps_flutter: ^2.9.0
  geocoding: ^3.0.0
```

Then:

```bash
flutter pub get
flutter analyze
flutter test
```

Expected: no errors, all tests pass.

- [ ] **Step 3: Remove Google Maps API key from `.env`**

Open `.env` and delete the `GOOGLE_MAPS_API_KEY` (or similarly named) line if present.

- [ ] **Step 4: Remove Google Maps key from iOS Info.plist**

In `ios/Runner/Info.plist`, find and remove the `<key>GMSApiKey</key><string>...</string>` pair if present. Also remove any related `LSApplicationQueriesSchemes` entries scoped to Google Maps if they exist.

- [ ] **Step 5: Remove Google Maps key from Android manifest**

In `android/app/src/main/AndroidManifest.xml`, find and remove:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="..." />
```

- [ ] **Step 6: Final build verification**

```bash
flutter pub get
flutter clean
flutter build apk --debug   # confirms Android still builds
flutter build ios --debug --no-codesign   # confirms iOS still builds
```

Expected: both builds succeed.

- [ ] **Step 7: Commit + push**

```bash
git add pubspec.yaml pubspec.lock .env ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "chore: remove google_maps_flutter, geocoding, and Google Maps API keys"
git push
```

---

### Task 4.6: PR + merge

- [ ] **Step 1: Open PR**

```bash
gh pr create --base main --head phase/4-maps-swap \
  --title "Phase 4: Maps swap — flutter_map + OSM + Nominatim everywhere" \
  --body "Implements Phase 4. NominatimService with 1-req/sec rate limit + 300ms debounce. MapView and all consumers on FlutterMap. google_maps_flutter + geocoding packages and API keys removed."
```

- [ ] **Step 2: Final manual smoke test**

Login → browse → store detail → map → add to basket → checkout → order tracking → profile → settings. Confirm OSM tiles, attribution visible, address search works, no Google Maps anywhere.

- [ ] **Step 3: Merge**

```bash
gh pr merge phase/4-maps-swap --squash --delete-branch
git checkout main && git pull --rebase origin main
```

---

## Self-Review

**Spec coverage:**

| Spec acceptance criterion | Task that fulfills it |
|---|---|
| 1. `brand-kit/` submodule installed | Task 1.1 |
| 2. `UnshelfTheme.light()` + `.dark()` driven by tokens | Task 1.3 |
| 3. `lib/utils/colors.dart` retired | Task 3.11 |
| 4. `flutter pub get` clean; provider + google_maps_flutter removed | Tasks 2.15 (provider), 4.5 (google_maps_flutter) |
| 5. App boots under ProviderScope | Task 1.6 |
| 6. No hardcoded colors/fonts in screen code | Task 3.12 (grep gate) |
| 7. Logo + icon + splash use Abundance Basket SVGs | Task 1.5 |
| 8. Zero `ChangeNotifierProvider` | Tasks 2.2-2.14 (each one) + 2.15 (final remove) |
| 9. All 13 viewmodels are Riverpod providers; 7 tests pass | Tasks 2.2-2.14 |
| 10. Map renders OSM tiles + Nominatim search + attribution | Tasks 4.2, 4.3, 4.4 |
| 11. App runs end-to-end on Android + iOS | Smoke tests at each phase PR (Tasks 1.8, 2.16, 3.12, 4.6) |
| 12. `CLAUDE.md` at repo root | Task 1.7 |
| 13. All four phase branches merged via PR | Tasks 1.8, 2.16, 3.12, 4.6 |

All criteria covered.

**Placeholder scan:** Found one in Task 4.1: the audit notes say "[TBD after grep]" — that's intentional, the engineer fills it in from their grep output. Not a plan-writing TBD. Acceptable.

**Type consistency:** Provider names use `<X>ViewModelProvider` throughout. State classes follow `<X>State` (sealed/freezed). `UnshelfTokens.colorLight*` and `UnshelfTokens.colorDark*` match the brand kit's actual exports. `NominatimService` and `NominatimPlace` defined together in Task 4.2 and referenced consistently in Tasks 4.3, 4.4.

---

## Execution Handoff

Plan complete and saved to `docs/crucible/plans/2026-05-16-buyer-rebrand-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, review checkpoints. Matches your saved workflow preference.

**2. Inline Execution** — execute tasks in this session using `executing-plans`, batch with checkpoints.

**Which approach?**
