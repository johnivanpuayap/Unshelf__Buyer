import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/viewmodels/settings_viewmodel.dart';

void main() {
  group('SettingsViewModel', () {
    late SettingsViewModel viewModel;

    setUp(() => viewModel = SettingsViewModel());

    test('starts with notifications enabled and English', () {
      expect(viewModel.settings.notificationsEnabled, isTrue);
      expect(viewModel.settings.language, 'English');
    });

    test('toggleNotifications updates the flag and notifies', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.toggleNotifications(false);

      expect(viewModel.settings.notificationsEnabled, isFalse);
      expect(viewModel.settings.language, 'English');
      expect(notified, isTrue);
    });

    test('changeLanguage updates the language and notifies', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.changeLanguage('Filipino');

      expect(viewModel.settings.language, 'Filipino');
      expect(viewModel.settings.notificationsEnabled, isTrue);
      expect(notified, isTrue);
    });
  });
}
