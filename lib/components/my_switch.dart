import 'package:flutter/material.dart';

class SwitchToggle extends StatefulWidget {
  const SwitchToggle({super.key});

  get isToggled => {null};

  @override
  State<SwitchToggle> createState() => _SwitchToggleState();
}

class _SwitchToggleState extends State<SwitchToggle> {
  bool isToggled = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Switch(
      value: isToggled,
      activeColor: cs.primary,
      onChanged: (bool value) {
        setState(() {
          isToggled = value;
        });
      },
    );
  }
}
