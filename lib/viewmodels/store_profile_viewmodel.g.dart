// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_profile_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StoreProfileViewModel)
final storeProfileViewModelProvider = StoreProfileViewModelFamily._();

final class StoreProfileViewModelProvider
    extends $NotifierProvider<StoreProfileViewModel, StoreProfileState> {
  StoreProfileViewModelProvider._(
      {required StoreProfileViewModelFamily super.from,
      required StoreModel super.argument})
      : super(
          retry: null,
          name: r'storeProfileViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storeProfileViewModelHash();

  @override
  String toString() {
    return r'storeProfileViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StoreProfileViewModel create() => StoreProfileViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoreProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoreProfileState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoreProfileViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storeProfileViewModelHash() =>
    r'873edf5d3bbefe33e71c8d62126ecd9eb84d4855';

final class StoreProfileViewModelFamily extends $Family
    with
        $ClassFamilyOverride<StoreProfileViewModel, StoreProfileState,
            StoreProfileState, StoreProfileState, StoreModel> {
  StoreProfileViewModelFamily._()
      : super(
          retry: null,
          name: r'storeProfileViewModelProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StoreProfileViewModelProvider call(
    StoreModel storeDetails,
  ) =>
      StoreProfileViewModelProvider._(argument: storeDetails, from: this);

  @override
  String toString() => r'storeProfileViewModelProvider';
}

abstract class _$StoreProfileViewModel extends $Notifier<StoreProfileState> {
  late final _$args = ref.$arg as StoreModel;
  StoreModel get storeDetails => _$args;

  StoreProfileState build(
    StoreModel storeDetails,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StoreProfileState, StoreProfileState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<StoreProfileState, StoreProfileState>,
        StoreProfileState,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
