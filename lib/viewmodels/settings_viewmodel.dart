import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/settings_model.dart';

part 'settings_viewmodel.g.dart';

@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsModel build() => SettingsModel(
        notificationsEnabled: true,
        language: 'English',
      );

  void toggleNotifications(bool value) {
    state = SettingsModel(
      notificationsEnabled: value,
      language: state.language,
    );
  }

  void changeLanguage(String newLanguage) {
    state = SettingsModel(
      notificationsEnabled: state.notificationsEnabled,
      language: newLanguage,
    );
  }
}
