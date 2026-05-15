/// FieldLabel — small-caps form field label used above every TextFormField
/// in auth screens and profile editing.
///
/// Extracted from the private _FieldLabel classes in:
///   1. authentication/views/login_view.dart
///   2. authentication/views/register_view.dart
///   3. authentication/views/forgot_password_view.dart
///   4. views/edit_profile_view.dart
library;

import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, required this.color});

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
