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
    return Switch(
      // This bool value toggles the switch.
      value: isToggled,
      activeColor: const Color(0xFF0AB68B),
      onChanged: (bool value) {
        // This is called when the user toggles the switch.
        setState(() {
          isToggled = value;
        });
      },
    );
  }
}
