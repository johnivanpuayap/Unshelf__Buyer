// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardViewModel)
final dashboardViewModelProvider = DashboardViewModelProvider._();

final class DashboardViewModelProvider
    extends $NotifierProvider<DashboardViewModel, DashboardState> {
  DashboardViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dashboardViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dashboardViewModelHash();

  @$internal
  @override
  DashboardViewModel create() => DashboardViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardState>(value),
    );
  }
}

String _$dashboardViewModelHash() =>
    r'66af9b5b0e7505ad70810340d742a63e15a25357';

abstract class _$DashboardViewModel extends $Notifier<DashboardState> {
  DashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DashboardState, DashboardState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DashboardState, DashboardState>,
        DashboardState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
