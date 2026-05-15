/// SettingsTile — a tappable row used in the profile settings list.
///
/// Displays a [leading] icon, [title], optional [subtitle], and a trailing
/// chevron.  Has a ripple tap and routes to the caller's [onTap].
///
/// Extracted in Group G for use in:
///   1. views/profile_view.dart (7 rows)
library;

import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  /// When true the tile's icon and title are rendered in [ColorScheme.error].
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final effectiveColor =
        destructive ? cs.error : (iconColor ?? cs.onSurface.withValues(alpha: 0.75));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: effectiveColor),
          ),
          title: Text(
            title,
            style: tt.bodyLarge?.copyWith(
              color: destructive ? cs.error : cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurface.withValues(alpha: 0.35),
            size: 20,
          ),
        ),
      ),
    );
  }
}
