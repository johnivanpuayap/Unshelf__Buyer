// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_address_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrderAddressViewModel)
final orderAddressViewModelProvider = OrderAddressViewModelProvider._();

final class OrderAddressViewModelProvider
    extends $NotifierProvider<OrderAddressViewModel, OrderAddressState> {
  OrderAddressViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'orderAddressViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$orderAddressViewModelHash();

  @$internal
  @override
  OrderAddressViewModel create() => OrderAddressViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderAddressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderAddressState>(value),
    );
  }
}

String _$orderAddressViewModelHash() =>
    r'e6e7dfd4e2af015442d3a32090b701abc047c787';

abstract class _$OrderAddressViewModel extends $Notifier<OrderAddressState> {
  OrderAddressState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OrderAddressState, OrderAddressState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<OrderAddressState, OrderAddressState>,
        OrderAddressState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
