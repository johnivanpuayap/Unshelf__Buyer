// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StoreViewModel)
final storeViewModelProvider = StoreViewModelFamily._();

final class StoreViewModelProvider
    extends $NotifierProvider<StoreViewModel, StoreState> {
  StoreViewModelProvider._(
      {required StoreViewModelFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'storeViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storeViewModelHash();

  @override
  String toString() {
    return r'storeViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StoreViewModel create() => StoreViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoreState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoreState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StoreViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storeViewModelHash() => r'f7084a04c5da1d295bfff1e05f5a60eee8b2c478';

final class StoreViewModelFamily extends $Family
    with
        $ClassFamilyOverride<StoreViewModel, StoreState, StoreState, StoreState,
            String> {
  StoreViewModelFamily._()
      : super(
          retry: null,
          name: r'storeViewModelProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StoreViewModelProvider call(
    String storeId,
  ) =>
      StoreViewModelProvider._(argument: storeId, from: this);

  @override
  String toString() => r'storeViewModelProvider';
}

abstract class _$StoreViewModel extends $Notifier<StoreState> {
  late final _$args = ref.$arg as String;
  String get storeId => _$args;

  StoreState build(
    String storeId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StoreState, StoreState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<StoreState, StoreState>, StoreState, Object?, Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
