// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsViewModel)
final settingsViewModelProvider = SettingsViewModelProvider._();

final class SettingsViewModelProvider
    extends $NotifierProvider<SettingsViewModel, SettingsModel> {
  SettingsViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsViewModelHash();

  @$internal
  @override
  SettingsViewModel create() => SettingsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsModel>(value),
    );
  }
}

String _$settingsViewModelHash() => r'8b4632a23e8035e71536d2b643de30c723e6bfbf';

abstract class _$SettingsViewModel extends $Notifier<SettingsModel> {
  SettingsModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SettingsModel, SettingsModel>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SettingsModel, SettingsModel>,
        SettingsModel,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
