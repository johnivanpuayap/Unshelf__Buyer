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
