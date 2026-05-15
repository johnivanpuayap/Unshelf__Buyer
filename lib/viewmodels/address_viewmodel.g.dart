// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddressViewModel)
final addressViewModelProvider = AddressViewModelProvider._();

final class AddressViewModelProvider
    extends $NotifierProvider<AddressViewModel, AddressState> {
  AddressViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'addressViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$addressViewModelHash();

  @$internal
  @override
  AddressViewModel create() => AddressViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressState>(value),
    );
  }
}

String _$addressViewModelHash() => r'181233d09b5f194e7602ac50af5b2c5c14abb0cb';

abstract class _$AddressViewModel extends $Notifier<AddressState> {
  AddressState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddressState, AddressState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AddressState, AddressState>,
        AddressState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
