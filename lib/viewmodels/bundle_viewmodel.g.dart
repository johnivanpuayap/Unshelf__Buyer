// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bundle_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BundleViewModel)
final bundleViewModelProvider = BundleViewModelProvider._();

final class BundleViewModelProvider
    extends $NotifierProvider<BundleViewModel, BundleState> {
  BundleViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bundleViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bundleViewModelHash();

  @$internal
  @override
  BundleViewModel create() => BundleViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BundleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BundleState>(value),
    );
  }
}

String _$bundleViewModelHash() => r'74f89294a5f0aee887b832b2703936d0797273bf';

abstract class _$BundleViewModel extends $Notifier<BundleState> {
  BundleState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BundleState, BundleState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<BundleState, BundleState>, BundleState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
