// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WalletViewModel)
final walletViewModelProvider = WalletViewModelProvider._();

final class WalletViewModelProvider
    extends $NotifierProvider<WalletViewModel, WalletState> {
  WalletViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'walletViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$walletViewModelHash();

  @$internal
  @override
  WalletViewModel create() => WalletViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletState>(value),
    );
  }
}

String _$walletViewModelHash() => r'f0a5c2b01b87934ab5fa3a5be27897341a291f33';

abstract class _$WalletViewModel extends $Notifier<WalletState> {
  WalletState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WalletState, WalletState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<WalletState, WalletState>, WalletState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
