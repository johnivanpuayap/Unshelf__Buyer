# Buyer UI/UX Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply design-system quality to every screen of the buyer Flutter app — auth flow first (shared design with seller), then 7 screen groups + a final components pass — shipping each group as its own PR into `main`.

**Architecture:** One feature branch per group, squash-merged via PR at exit. Auth flow ships the full set of four screens (login, register, forgot password, reset email sent) plus an SVG-inline-fill fix and a refined `InputDecorationTheme`. Subsequent groups redesign screens in place — composition, spacing scale, typography hierarchy, brand components — referencing the auth screens as the quality bar and the brand kit's `preview.html` for component patterns. Reusable widgets get extracted into `lib/components/` only when they reach three uses.

**Tech Stack:** Flutter 3.41 · Dart · Riverpod 4.x (`@riverpod` codegen, already in place from sub-project 3) · flutter_map · flutter_svg · firebase_auth · firebase_storage · cloud_firestore · google_fonts · brand-kit submodule.

**Spec:** `docs/crucible/specs/2026-05-16-buyer-ui-redesign.md`
**Auth design contract (shared with seller):** `brand-kit/docs/crucible/auth-screens.md`
**Brand reference:** `brand-kit/docs/crucible/design.md` · `brand-kit/docs/crucible/preview.html`
**Uniqueness rule:** memory `[[unshelf-buyer-seller-uniqueness]]` — buyer and seller stay visually distinct; ONLY auth-flow screens are shared.

**Conventions:**
- Per-group branch: `redesign/<group-letter>-<short-name>` (e.g., `redesign/A-auth-flow`)
- Atomic commits with Conventional Commits prefixes (`feat(ui)`, `fix(ui)`, `chore`, `refactor`, etc.)
- **No `Co-Authored-By` trailers**
- Push after every commit
- One PR per group via `gh pr create --repo johnivanpuayap/unshelf-buyer`
- Merge via `gh pr merge <num> --squash --delete-branch --repo johnivanpuayap/unshelf-buyer`
- Git identity already configured: `johnivanpuayap@gmail.com`
- After each group's merge, the next group branches from fresh `main`
- All `gh` commands must include `--repo johnivanpuayap/unshelf-buyer` (the repo has an `upstream` remote pointing to the org — never let gh auto-pick)

---

## File Structure

```
personal-projects/unshelf-buyer/
├── assets/images/logos/                        [Group A — SVGs rewritten with inline fills]
├── lib/
│   ├── authentication/views/
│   │   ├── login_view.dart                     [Group A — rebuild]
│   │   ├── register_view.dart                  [Group A — rebuild]
│   │   ├── forgot_password_view.dart           [Group A — NEW]
│   │   └── reset_email_sent_view.dart          [Group A — NEW]
│   ├── theme/
│   │   └── unshelf_theme.dart                  [Group A — refine InputDecorationTheme]
│   ├── components/                             [Groups B-H emergent extracts + I final pass]
│   │   └── README.md                           [Group I — NEW: catalog of components]
│   └── views/
│       ├── home_view.dart                      [Group B — redesign]
│       ├── notifications_view.dart             [Group B — redesign]
│       ├── category_view.dart                  [Group C]
│       ├── search_view.dart                    [Group C]
│       ├── stores_view.dart                    [Group C]
│       ├── store_view.dart                     [Group C]
│       ├── store_reviews_view.dart             [Group C]
│       ├── product_view.dart                   [Group D]
│       ├── product_bundle_view.dart            [Group D]
│       ├── review_view.dart                    [Group D]
│       ├── basket_view.dart                    [Group E]
│       ├── basket_checkout_view.dart           [Group E]
│       ├── order_placed_view.dart              [Group E]
│       ├── order_address_view.dart             [Group E]
│       ├── order_history_view.dart             [Group F]
│       ├── order_details_view.dart             [Group F]
│       ├── order_tracking_view.dart            [Group F]
│       ├── profile_orders_view.dart            [Group F — resolve: empty file]
│       ├── profile_view.dart                   [Group G]
│       ├── edit_profile_view.dart              [Group G]
│       ├── profile_favorites_view.dart         [Group G]
│       ├── profile_following_view.dart         [Group G]
│       ├── edit_address_view.dart              [Group G — resolve: commented file]
│       ├── store_address_view.dart             [Group G — non-map chrome only]
│       ├── chat_view.dart                      [Group H]
│       ├── chat_screen.dart                    [Group H]
│       ├── report_view.dart                    [Group H]
│       └── map_view.dart                       [Group H — non-FlutterMap chrome only]
└── docs/crucible/
    ├── specs/2026-05-16-buyer-ui-redesign.md   [exists]
    └── plans/2026-05-16-buyer-ui-redesign-implementation.md  [this file]
```

---

## Quality Bar (referenced by every group)

The auth screens that ship in Group A set the quality bar for the whole sub-project. When redesigning later screens, the subagent should be able to point at the auth screens and answer "yes, this screen is at that quality level". The bar includes:

- **Layout:** content centered with `maxWidth: 420` on web/tablet (or full-width on phone with 24px horizontal padding), `SingleChildScrollView` wrapping the body, `SafeArea` respected. No AppBar on hero/landing-style screens; AppBar present only for navigated-into screens with a clear back action.
- **Typography hierarchy:** display/headline use DM Serif Display via `Theme.of(context).textTheme.{displayLarge|headlineMedium|titleLarge}`; body/labels use DM Sans via `bodyLarge|bodyMedium|labelLarge`. No hardcoded `TextStyle(fontFamily: ...)`.
- **Spacing scale:** 4/8/16/20/24/32/48px only. No `EdgeInsets.all(10)` / `15` / `21`.
- **Cards:** `colorScheme.surfaceContainerHighest` fill, 14px radius, two-layer shadow:
  ```dart
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .02), offset: Offset(0, 1), blurRadius: 0),
    BoxShadow(color: Color(0xFF1F2A20).withValues(alpha: .06), offset: Offset(0, 8), blurRadius: 28),
  ],
  ```
- **Buttons:**
  - Primary: full-width `ElevatedButton`, 52px tall, pill, loading spinner during async actions (disable `onPressed`)
  - Secondary: `OutlinedButton` or `TextButton` — never two equal-weight primary buttons
- **Inputs:** field label as a separate `Text` widget ABOVE the input (`labelLarge` DM Sans 600), 8px gap, then `TextFormField` with theme defaults only — no per-field border/fill overrides. Hint text is short and example-driven.
- **Empty / error / loading states:** every list view has all three. Loading = `CircularProgressIndicator` centered; empty = icon + headline + body explanation + (optional) primary CTA; error = same shape as empty but with a retry button.
- **CTA copy:** plain transactional only ("Buy now", "Add to basket", "Order", "Reserve", "Checkout", "View details"). NEVER "Rescue", "Save", "Snag", "Grab".
- **State badges:** descriptive ("Rescued", "Expires in 2 days", "Saved from waste") — fine to use as labels, not buttons.
- **No glassmorphism, no `Colors.white`, no `Color(0xFF...)` in screen code, no `TextStyle(fontFamily:)` in screen code.**

---

## Group A — Auth Flow

Branch: `redesign/A-auth-flow`

Implements the full shared auth flow per `brand-kit/docs/crucible/auth-screens.md`. **This sets the quality bar referenced by every later group.** Four screens (login, register, forgot password, reset email sent) + SVG inline-fill fix + InputDecorationTheme refinement.

### Task A.1: Branch + SVG inline-fill fix

**Files:**
- Modify: `assets/images/logos/logo.svg`
- Modify: `assets/images/logos/logo-icon.svg`

The brand-kit SVGs use `<defs><style>` blocks with CSS classes like `class="primary"`. `flutter_svg` does not reliably resolve CSS classes, so the logos render monochrome black at runtime. Rewrite with inline `fill="..."` and `stroke="..."` attributes.

- [ ] **Step 1: Branch off main**

```bash
cd "C:/Users/John Ivan/personal-projects/unshelf-buyer"
git checkout main && git pull --rebase origin main
git checkout -b redesign/A-auth-flow
git push -u origin redesign/A-auth-flow
```

- [ ] **Step 2: Replace `assets/images/logos/logo-icon.svg`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"
     role="img" aria-labelledby="title desc">
  <title id="title">Unshelf icon</title>
  <desc id="desc">A market basket overflowing with a pan de sal, a leafy sprig, and a mango.</desc>
  <g id="icon" transform="translate(0,10)">
    <ellipse cx="58" cy="84" rx="26" ry="13" fill="#E89A2D"/>
    <line x1="36" y1="84" x2="80" y2="84" stroke="#B26C1C" stroke-width="2" stroke-linecap="round" opacity="0.55"/>
    <path d="M 44 78 Q 58 70, 72 78" stroke="#E89A2D" stroke-width="3" fill="none" stroke-linecap="round"/>

    <path d="M 100 92 Q 100 32, 92 18" stroke="#28602F" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <ellipse cx="92" cy="30" rx="9" ry="16" fill="#3F8E4A" transform="rotate(-28 92 30)"/>
    <ellipse cx="112" cy="50" rx="8" ry="14" fill="#3F8E4A" transform="rotate(32 112 50)"/>
    <ellipse cx="90" cy="68" rx="7" ry="12" fill="#3F8E4A" transform="rotate(-25 90 68)"/>

    <ellipse cx="142" cy="80" rx="18" ry="17" fill="#FFD27F"/>
    <ellipse cx="136" cy="76" rx="6" ry="5" fill="#E89A2D" opacity="0.55"/>
    <path d="M 142 64 Q 144 58, 150 56" stroke="#28602F" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <ellipse cx="152" cy="56" rx="5" ry="9" fill="#3F8E4A" transform="rotate(45 152 56)"/>

    <path d="M 28 96 Q 28 162, 100 162 Q 172 162, 172 96" stroke="#3F8E4A" stroke-width="12" fill="none" stroke-linecap="round"/>
    <ellipse cx="100" cy="96" rx="72" ry="9" fill="#3F8E4A"/>
    <ellipse cx="100" cy="93" rx="60" ry="3.5" fill="#28602F" opacity="0.5"/>
    <path d="M 40 122 Q 100 130, 160 122" stroke="#28602F" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.35"/>
    <path d="M 46 142 Q 100 148, 154 142" stroke="#28602F" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.35"/>
  </g>
</svg>
```

- [ ] **Step 3: Replace `assets/images/logos/logo.svg`** (same body as logo-icon, plus the wordmark group)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 200"
     role="img" aria-labelledby="title desc">
  <title id="title">Unshelf</title>
  <desc id="desc">Abundance Basket logo with the unshelf wordmark.</desc>
  <g id="icon" transform="translate(0,10)">
    <ellipse cx="58" cy="84" rx="26" ry="13" fill="#E89A2D"/>
    <line x1="36" y1="84" x2="80" y2="84" stroke="#B26C1C" stroke-width="2" stroke-linecap="round" opacity="0.55"/>
    <path d="M 44 78 Q 58 70, 72 78" stroke="#E89A2D" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M 100 92 Q 100 32, 92 18" stroke="#28602F" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <ellipse cx="92" cy="30" rx="9" ry="16" fill="#3F8E4A" transform="rotate(-28 92 30)"/>
    <ellipse cx="112" cy="50" rx="8" ry="14" fill="#3F8E4A" transform="rotate(32 112 50)"/>
    <ellipse cx="90" cy="68" rx="7" ry="12" fill="#3F8E4A" transform="rotate(-25 90 68)"/>
    <ellipse cx="142" cy="80" rx="18" ry="17" fill="#FFD27F"/>
    <ellipse cx="136" cy="76" rx="6" ry="5" fill="#E89A2D" opacity="0.55"/>
    <path d="M 142 64 Q 144 58, 150 56" stroke="#28602F" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    <ellipse cx="152" cy="56" rx="5" ry="9" fill="#3F8E4A" transform="rotate(45 152 56)"/>
    <path d="M 28 96 Q 28 162, 100 162 Q 172 162, 172 96" stroke="#3F8E4A" stroke-width="12" fill="none" stroke-linecap="round"/>
    <ellipse cx="100" cy="96" rx="72" ry="9" fill="#3F8E4A"/>
    <ellipse cx="100" cy="93" rx="60" ry="3.5" fill="#28602F" opacity="0.5"/>
    <path d="M 40 122 Q 100 130, 160 122" stroke="#28602F" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.35"/>
    <path d="M 46 142 Q 100 148, 154 142" stroke="#28602F" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.35"/>
  </g>
  <g id="wordmark">
    <text x="220" y="138" font-family="DM Serif Display, 'Times New Roman', serif" font-size="120" font-weight="400" fill="#28602F">unshelf</text>
  </g>
</svg>
```

- [ ] **Step 4: Verify + commit**

```bash
flutter analyze 2>&1 | tail -3
git add assets/images/logos/logo.svg assets/images/logos/logo-icon.svg
git commit -m "fix(assets): inline SVG fills so flutter_svg renders brand colors"
git push
```

### Task A.2: Refine InputDecorationTheme

**Files:**
- Modify: `lib/theme/unshelf_theme.dart` — replace the `_inputDecorationTheme` static helper

- [ ] **Step 1: Replace the helper body**

Find `static InputDecorationTheme _inputDecorationTheme(ColorScheme cs)` and replace it entirely with:

```dart
  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.45),
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.75),
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: cs.primary,
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error.withValues(alpha: 0.7), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      );
```

- [ ] **Step 2: Verify + commit**

```bash
flutter analyze lib/theme/ 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/theme/unshelf_theme.dart
git commit -m "feat(theme): refine InputDecorationTheme — 16/16 padding, subtle borders, primary focus ring"
git push
```

### Task A.3: Rebuild `login_view.dart`

**Files:**
- Replace: `lib/authentication/views/login_view.dart` (full replacement)

- [ ] **Step 1: Write the new login view**

Replace the entire file with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/authentication/views/register_view.dart';
import 'package:unshelf_buyer/authentication/views/forgot_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _submitting = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _snack('User not found in database.');
        return;
      }
      final banned = (userDoc['isBanned'] as bool?) ?? false;
      if (banned) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _snack('Your account is banned. Please contact support.');
        return;
      }
      final role = userDoc['type'] as String?;
      if (role != 'buyer') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _snack('User has a different role');
        return;
      }
      _snack('Signed in');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeView()),
      );
    } on FirebaseAuthException catch (e) {
      _snack(switch (e.code) {
        'user-not-found' => 'No user found for that email.',
        'wrong-password' => 'Wrong password.',
        'invalid-credential' => 'Email or password is incorrect.',
        _ => 'Sign in failed. Please try again.',
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logos/logo-icon.svg',
                        height: 112,
                        semanticsLabel: 'Unshelf',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome back',
                        style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Eat well. Waste less.',
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    _FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () =>
                              setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ForgotPasswordView())),
                        child: Text('Forgot password?',
                            style: tt.labelLarge?.copyWith(color: cs.primary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _login,
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: cs.onPrimary))
                            : Text('Sign in',
                                style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New here?',
                            style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7))),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterView())),
                          child: Text('Create an account',
                              style: tt.labelLarge?.copyWith(color: cs.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/authentication/views/login_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Expect: 0 errors, 41/41 tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/authentication/views/login_view.dart
git commit -m "feat(auth): rebuild login view per shared auth-screens spec"
git push
```

### Task A.4: Rebuild `register_view.dart`

**Files:**
- Replace: `lib/authentication/views/register_view.dart`

- [ ] **Step 1: Write the new register view**

Replace the entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _submitting = false;

  static const _defaultAvatarUrl =
      'https://firebasestorage.googleapis.com/v0/b/unshelf-d4567.appspot.com/o/user_avatars%2FDvVHPPSWMtV7GBFjSW1jymsv1op1.png?alt=media&token=084a7a1a-f962-4348-9bb7-7d1ef3476856';

  Future<void> _saveUserData(User user, String name, String phoneNumber) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email,
      'phone_number': phoneNumber,
      'profileImageUrl': _defaultAvatarUrl,
      'type': 'buyer',
      'isBanned': false,
      'points': 0,
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _saveUserData(
        cred.user!,
        _nameController.text.trim(),
        _phoneNumberController.text.trim(),
      );
      if (!mounted) return;
      _snack('Registration successful');
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
    } on FirebaseAuthException catch (e) {
      _snack(switch (e.code) {
        'weak-password' => 'Password is too weak.',
        'email-already-in-use' => 'An account already exists for that email.',
        _ => 'Something went wrong: ${e.message ?? 'try again later'}',
      });
    } catch (_) {
      _snack('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: SvgPicture.asset('assets/images/logos/logo-icon.svg',
                          height: 88, semanticsLabel: 'Unshelf'),
                    ),
                    const SizedBox(height: 24),
                    Text('Create your account',
                        style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Start rescuing near-expiry food near you.',
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    _FieldLabel('Full name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(hintText: 'e.g. Maria Santos'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Phone number', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      decoration: const InputDecoration(hintText: '09XX XXX XXXX'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 11) return 'Must be at least 11 digits';
                        if (!digits.startsWith('09')) return 'Must start with 09';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () =>
                              setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Confirm password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmVisible,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        hintText: 'Type it again',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () =>
                              setState(() => _confirmVisible = !_confirmVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _register,
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: cs.onPrimary))
                            : Text('Create account',
                                style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "By signing up, you agree to Unshelf's Terms and Privacy Policy.",
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already a member?',
                            style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7))),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginView())),
                          child: Text('Sign in',
                              style: tt.labelLarge?.copyWith(color: cs.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}
```

- [ ] **Step 2: Verify + commit**

```bash
flutter analyze lib/authentication/views/register_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/authentication/views/register_view.dart
git commit -m "feat(auth): rebuild register view per shared auth-screens spec"
git push
```

### Task A.5: Create `forgot_password_view.dart`

**Files:**
- Create: `lib/authentication/views/forgot_password_view.dart`

- [ ] **Step 1: Write the new view**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';
import 'package:unshelf_buyer/authentication/views/reset_email_sent_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final email = _emailController.text.trim();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResetEmailSentView(email: email)),
      );
    } on FirebaseAuthException catch (e) {
      // Per spec: don't leak user-existence — treat user-not-found as success too.
      if (e.code == 'user-not-found') {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResetEmailSentView(email: email)),
        );
        return;
      }
      _snack(e.code == 'too-many-requests'
          ? 'Too many requests. Try again in a moment.'
          : 'Could not send reset link. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: SvgPicture.asset('assets/images/logos/logo-icon.svg',
                          height: 88, semanticsLabel: 'Unshelf'),
                    ),
                    const SizedBox(height: 24),
                    Text('Reset your password',
                        style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text("Enter your email and we'll send you a reset link.",
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    _FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: cs.onPrimary))
                            : Text('Send reset link',
                                style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Remember your password?',
                            style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7))),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginView())),
                          child: Text('Sign in',
                              style: tt.labelLarge?.copyWith(color: cs.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}
```

- [ ] **Step 2: Verify + commit**

```bash
flutter analyze lib/authentication/views/forgot_password_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/authentication/views/forgot_password_view.dart
git commit -m "feat(auth): add forgot-password screen per shared spec"
git push
```

### Task A.6: Create `reset_email_sent_view.dart`

**Files:**
- Create: `lib/authentication/views/reset_email_sent_view.dart`

- [ ] **Step 1: Write the new view**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';

class ResetEmailSentView extends StatefulWidget {
  const ResetEmailSentView({super.key, required this.email});
  final String email;

  @override
  State<ResetEmailSentView> createState() => _ResetEmailSentViewState();
}

class _ResetEmailSentViewState extends State<ResetEmailSentView> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      _snack('Reset link sent.');
      _startCooldown();
    } catch (_) {
      _snack('Could not resend. Try again in a moment.');
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldownSeconds -= 1);
      if (_cooldownSeconds <= 0) t.cancel();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Icon(Icons.mark_email_read_outlined,
                        size: 72, color: cs.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('Check your email',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: tt.bodyLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65)),
                      children: [
                        const TextSpan(text: 'We sent a password reset link to '),
                        TextSpan(
                            text: widget.email,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.85))),
                        const TextSpan(
                            text: '. Tap the link to set a new password.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginView())),
                      child: Text('Back to sign in',
                          style: tt.labelLarge?.copyWith(color: cs.primary)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Didn't get it? Check spam, or",
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55))),
                      TextButton(
                        onPressed: _cooldownSeconds > 0 ? null : _resend,
                        child: Text(
                          _cooldownSeconds > 0
                              ? 'resend (${_cooldownSeconds}s)'
                              : 'resend',
                          style: tt.labelLarge?.copyWith(
                              color: _cooldownSeconds > 0
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify + commit**

```bash
flutter analyze lib/authentication/views/reset_email_sent_view.dart 2>&1 | tail -3
flutter test 2>&1 | tail -3
git add lib/authentication/views/reset_email_sent_view.dart
git commit -m "feat(auth): add reset-email-sent confirmation screen per shared spec"
git push
```

### Task A.7: Verify build + open PR + merge

- [ ] **Step 1: Build for web to verify everything compiles**

```bash
flutter build web --release 2>&1 | tail -5
```

Expected: `✓ Built build\web`.

- [ ] **Step 2: Open PR**

```bash
gh pr create --repo johnivanpuayap/unshelf-buyer --base main --head redesign/A-auth-flow \
  --title "Redesign Group A: full auth flow + SVG fix + input theme" \
  --body "Implements Group A of the buyer UI/UX redesign (sub-project 3.1). Aligns with the shared auth design at \`brand-kit/docs/crucible/auth-screens.md\`. Sets the quality bar for the rest of the redesign.

Includes: SVG inline-fill fix, refined InputDecorationTheme, rebuilt login + register screens, new forgot-password + reset-email-sent screens."
```

- [ ] **Step 3: Merge**

```bash
PR=$(gh pr list --repo johnivanpuayap/unshelf-buyer --head redesign/A-auth-flow --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-buyer $PR --squash --delete-branch
git checkout main && git pull --rebase origin main
```

---

## Groups B–H — Screen Redesigns

Each group is one subagent invocation. Each subagent reads the spec, the shared design references, and Group A's shipped screens as the quality bar — then redesigns its assigned files in place, commits per screen, opens a PR, merges via squash.

### Group B — Home + Dashboard

Branch: `redesign/B-home`

**Files:**
- Modify: `lib/views/home_view.dart`
- Modify: `lib/views/notifications_view.dart`

**Per the IA memory rule (`[[unshelf-rebrand]]`):** the main dashboard is **products**, not stats. The home view should lead with browseable inventory. Suggested composition (the subagent designs the details):

```
[Top bar]    Greeting/avatar/search affordance
[Hero]       "Discover near-expiry food in Cebu" headline + Cebu-rooted lede
[Categories] Horizontal scrolling chip row (Bakery, Produce, Dairy, Pantry, Snacks, Drinks) with counts
[Nearby]     Section header "Stores near you" + horizontal ScrollView of StoreCard
[Expiring]   Section header "Expiring soon" + vertical list of ProductCard
[Bottom nav] (handled by existing CustomNavigationBar component)
```

`notifications_view.dart` follows the standard list pattern: section headers grouped by time ("Today", "Earlier"), each notification as a card with icon, title, body, timestamp.

**Tasks for the subagent:**

- [ ] **B.1** Branch off main: `git checkout main && git pull --rebase origin main && git checkout -b redesign/B-home && git push -u origin redesign/B-home`
- [ ] **B.2** Read the current `lib/views/home_view.dart`, `lib/views/notifications_view.dart`, all referenced viewmodels and components. Understand what data flows.
- [ ] **B.3** Redesign `home_view.dart`. Commit: `git commit -m "feat(ui): redesign home view to lead with products and Cebu-rooted hero"`. Push.
- [ ] **B.4** Redesign `notifications_view.dart`. Commit: `git commit -m "feat(ui): redesign notifications view with time-grouped sections"`. Push.
- [ ] **B.5** If any pattern was used 3+ times across home + auth + anywhere else, extract to `lib/components/` and update callers. Commit + push.
- [ ] **B.6** Run `flutter test` (expect 41+ pass) and `flutter analyze` (no new errors). Run `flutter build web --release` to confirm.
- [ ] **B.7** `gh pr create --repo johnivanpuayap/unshelf-buyer --base main --head redesign/B-home --title "Redesign Group B: home + notifications" --body "Per sub-project 3.1 plan."` Merge via squash. Sync main.

### Group C — Browsing

Branch: `redesign/C-browsing`

**Files:**
- Modify: `lib/views/category_view.dart`
- Modify: `lib/views/search_view.dart`
- Modify: `lib/views/stores_view.dart`
- Modify: `lib/views/store_view.dart`
- Modify: `lib/views/store_reviews_view.dart`

**Design intent:**
- `category_view.dart` — grid of ProductCard for a single category. AppBar with category name + filter affordance.
- `search_view.dart` — search bar at top, results below as ProductCard list. Empty state when no query; loading + empty + error states for results.
- `stores_view.dart` — list of stores with StoreCard.
- `store_view.dart` — store hero (cover, name, rating, location, hours), then the store's listings as ProductCard grid, then a "See reviews" link.
- `store_reviews_view.dart` — list of reviews (rating, body, reviewer, timestamp).

**Tasks (B-style — same pattern):**

- [ ] **C.1** Branch + push
- [ ] **C.2–C.6** One commit per screen
- [ ] **C.7** Component extractions if needed (likely `ProductCard`, `StoreCard`, `EmptyState`)
- [ ] **C.8** Verify + PR + merge

### Group D — Product detail + reviews

Branch: `redesign/D-product`

**Files:**
- Modify: `lib/views/product_view.dart`
- Modify: `lib/views/product_bundle_view.dart`
- Modify: `lib/views/review_view.dart`

**Design intent:**
- `product_view.dart` — image carousel up top, badges (expiry, discount, rescued), product title (DM Serif Display, large), price block (current + struck-through old), store info card (tap to navigate to store), description, quantity stepper, full-width primary "Add to basket" CTA pinned at bottom or below content.
- `product_bundle_view.dart` — similar shape, but shows the bundle's component items as a list.
- `review_view.dart` — form to leave a review: star rating selector, text area, submit button.

**Tasks (B-style):** D.1 branch → D.2–D.4 per-screen commits → D.5 component extraction → D.6 verify + PR + merge.

### Group E — Basket + checkout

Branch: `redesign/E-basket`

**Files:**
- Modify: `lib/views/basket_view.dart`
- Modify: `lib/views/basket_checkout_view.dart`
- Modify: `lib/views/order_placed_view.dart`
- Modify: `lib/views/order_address_view.dart` (non-map UI; FlutterMap widget stays)

**Design intent:**
- `basket_view.dart` — list of BasketRow (thumb, name, store, quantity stepper, line price), summary card at bottom (subtotal, fees, total), full-width "Checkout" CTA.
- `basket_checkout_view.dart` — collapsed sections for address, pickup window, payment method, order summary; "Place order" CTA. Each section is a card with section header + tappable row to edit.
- `order_placed_view.dart` — success state. Center icon (existing `assets/images/salad.png` works as a temporary; ideally an Unshelf-branded illustration later), "Order placed" headline, order number, "Track order" + "Back to home" CTAs.
- `order_address_view.dart` — non-map chrome: top app bar, address suggestion list (use `NominatimService` per Phase 4), confirm button. The FlutterMap widget itself stays as-is.

**Tasks (B-style):** E.1 → E.2–E.5 per-screen → E.6 components → E.7 verify + PR + merge.

### Group F — Orders + tracking

Branch: `redesign/F-orders`

**Files:**
- Modify: `lib/views/order_history_view.dart`
- Modify: `lib/views/order_details_view.dart`
- Modify: `lib/views/order_tracking_view.dart`
- Resolve: `lib/views/profile_orders_view.dart` (currently empty file — delete it if there are no references; if referenced, rebuild as a thin wrapper around `OrderHistoryView`)

**Design intent:**
- `order_history_view.dart` — segmented control (Active / Completed / Cancelled) + list of OrderCard.
- `order_details_view.dart` — order header (status, number, date), store card, items list, totals breakdown, action buttons (cancel if applicable, track, contact store).
- `order_tracking_view.dart` — status timeline (Order placed → Confirmed → Ready for pickup → Picked up), embedded FlutterMap showing store location + ETA if relevant.

**Tasks:** F.1 → F.2–F.4 per-screen + F.5 resolve `profile_orders_view.dart` → F.6 verify + PR + merge.

### Group G — Profile + settings + addresses

Branch: `redesign/G-profile`

**Files:**
- Modify: `lib/views/profile_view.dart`
- Modify: `lib/views/edit_profile_view.dart`
- Modify: `lib/views/profile_favorites_view.dart`
- Modify: `lib/views/profile_following_view.dart`
- Resolve: `lib/views/edit_address_view.dart` (currently fully commented — delete if no references; rebuild if referenced)
- Modify: `lib/views/store_address_view.dart` (non-map chrome)

**Design intent:**
- `profile_view.dart` — header with avatar + name + email, then a list of SettingsTile rows (Orders, Favorites, Following, Edit profile, Addresses, Settings, Sign out).
- `edit_profile_view.dart` — same field-label-above-input pattern as auth, save CTA at bottom.
- `profile_favorites_view.dart` / `profile_following_view.dart` — list views with empty states.
- `store_address_view.dart` — non-map chrome: app bar with store name, FlutterMap stays.

**Tasks:** G.1 → G.2–G.6 per-screen + G.7 resolve `edit_address_view.dart` → G.8 verify + PR + merge.

### Group H — Chat + reports + map

Branch: `redesign/H-chat-reports-map`

**Files:**
- Modify: `lib/views/chat_view.dart`
- Modify: `lib/views/chat_screen.dart`
- Modify: `lib/views/report_view.dart`
- Modify: `lib/views/map_view.dart` (non-FlutterMap chrome only)

**Design intent:**
- `chat_view.dart` — list of conversations: store avatar, store name, last message preview, timestamp, unread badge.
- `chat_screen.dart` — message bubbles (use existing `ChatBubble` component, retheme if needed), composer at bottom with text field + send button.
- `report_view.dart` — form: select reason (radio group), description textarea, submit CTA.
- `map_view.dart` — non-map chrome (app bar, FAB for "filter", search overlay if exists). FlutterMap widget itself stays.

**Tasks:** H.1 → H.2–H.5 per-screen → H.6 verify + PR + merge.

---

## Group I — Components final pass + README

Branch: `redesign/I-components`

**Files:**
- Audit: `lib/components/`
- Create: `lib/components/README.md`

**Tasks:**

- [ ] **I.1** Branch off main: `git checkout main && git pull --rebase origin main && git checkout -b redesign/I-components && git push -u origin redesign/I-components`

- [ ] **I.2** List every file in `lib/components/`. For each, identify:
  - What it does in one line
  - Where it's used (`grep -rn "ComponentName" lib/`)
  - Whether it's well-named, focused, and theme-driven (no hardcoded colors/fonts)

- [ ] **I.3** Promote/rename/refactor as needed. If a component is used in only one place, consider inlining. If a widget pattern appeared 3+ times across the redesign groups but wasn't extracted, extract it now.

- [ ] **I.4** Create `lib/components/README.md` with the format:

````markdown
# Buyer Components

Reusable widgets for the buyer app. Each entry lists purpose, key props, example usage.

> **Per the uniqueness rule (`[[unshelf-buyer-seller-uniqueness]]`):** these components are buyer-specific. The seller app has its own components. The only shared UI between apps is the auth flow (per `brand-kit/docs/crucible/auth-screens.md`).

## ComponentName

What it does in one sentence.

**File:** `lib/components/component_name.dart`

**Props:** ...

**Example:**
```dart
ComponentName(prop1: ..., prop2: ...)
```

**Used by:** ...
````

  Repeat for every component.

- [ ] **I.5** Verify: `flutter test`, `flutter analyze`, `flutter build web --release`. All green.

- [ ] **I.6** Commit each substantive change atomically: extraction commits, rename commits, README commit. Push each.

- [ ] **I.7** PR + merge:

```bash
gh pr create --repo johnivanpuayap/unshelf-buyer --base main --head redesign/I-components \
  --title "Redesign Group I: components audit + README" \
  --body "Final pass on lib/components/. Extracts emergent patterns. Adds catalog README."
PR=$(gh pr list --repo johnivanpuayap/unshelf-buyer --head redesign/I-components --json number --jq '.[0].number')
gh pr merge --repo johnivanpuayap/unshelf-buyer $PR --squash --delete-branch
git checkout main && git pull --rebase origin main
```

---

## Self-Review

**Spec coverage:**

| Spec acceptance criterion | Task that fulfills it |
|---|---|
| Every non-auth group A-I redesigned | Groups B-I |
| Buyer auth conforms to shared spec | Group A (tasks A.3–A.6) |
| `lib/components/README.md` exists | Group I (task I.4) |
| 41+ tests pass | Verified at end of every group |
| `flutter analyze` no new errors | Verified at end of every group |
| `flutter build web --release` succeeds | Verified at end of every group |
| Manual smoke test on Chrome web | Out-of-band per group (subagent confirms post-merge) |
| No `AppColors`, no hardcoded screen colors/fonts | Enforced by the Quality Bar; verified per group |
| All CTAs plain transactional | Enforced by the Quality Bar |
| Two empty files resolved | Group F (F.5) + Group G (G.7) |
| Brand-kit auth-screens.md referenced from buyer CLAUDE.md | Add to existing CLAUDE.md as part of Group A (task A.7 acceptance — verify and update if needed) |

**Placeholder scan:** Group B-H tasks reference the Quality Bar and the brand-kit references rather than spelling out every widget. This is intentional per the spec ("component extraction by three-uses rule, not upfront design system") — each subagent applies design judgment per group. Acceptable because: (1) the quality bar in Group A is the concrete reference, (2) the spec specifies acceptance criteria, (3) the subagent has the brand kit `preview.html` and `design.md` as design references. NOT a TBD placeholder — it's a deliberate design-judgment delegation.

**Type consistency:** `_FieldLabel` is defined as a file-private widget in each auth screen (login, register, forgot). If Group I extracts it to `lib/components/field_label.dart`, all four auth screens get updated together. Future groups should follow.

---

## Execution Handoff

Plan complete and saved to `docs/crucible/plans/2026-05-16-buyer-ui-redesign-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per group, two-stage review on Group A's substantive tasks, single-pass review on B–H/I groups (the Quality Bar enforces consistency). Matches your saved workflow preference.

**2. Inline Execution** — execute groups in this session using `executing-plans`, batch with checkpoints between groups.

**Which approach?**
