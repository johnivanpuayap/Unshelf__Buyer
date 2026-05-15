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
