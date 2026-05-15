import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/viewmodels/settings_viewmodel.dart';

void main() {
  group('SettingsViewModel', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('starts with notifications enabled and English', () {
      final container = makeContainer();
      final settings = container.read(settingsViewModelProvider);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.language, 'English');
    });

    test('toggleNotifications updates the flag', () {
      final container = makeContainer();

      container.read(settingsViewModelProvider.notifier).toggleNotifications(false);

      final settings = container.read(settingsViewModelProvider);
      expect(settings.notificationsEnabled, isFalse);
      expect(settings.language, 'English');
    });

    test('toggleNotifications notifies listeners', () {
      final container = makeContainer();
      var notified = false;
      container.listen(settingsViewModelProvider, (_, __) => notified = true);

      container.read(settingsViewModelProvider.notifier).toggleNotifications(false);

      expect(notified, isTrue);
    });

    test('changeLanguage updates the language', () {
      final container = makeContainer();

      container.read(settingsViewModelProvider.notifier).changeLanguage('Filipino');

      final settings = container.read(settingsViewModelProvider);
      expect(settings.language, 'Filipino');
      expect(settings.notificationsEnabled, isTrue);
    });

    test('changeLanguage notifies listeners', () {
      final container = makeContainer();
      var notified = false;
      container.listen(settingsViewModelProvider, (_, __) => notified = true);

      container.read(settingsViewModelProvider.notifier).changeLanguage('Filipino');

      expect(notified, isTrue);
    });
  });
}
