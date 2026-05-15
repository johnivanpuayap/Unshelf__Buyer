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
