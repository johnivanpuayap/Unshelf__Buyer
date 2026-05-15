// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ListingViewModel)
final listingViewModelProvider = ListingViewModelProvider._();

final class ListingViewModelProvider
    extends $NotifierProvider<ListingViewModel, ListingState> {
  ListingViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'listingViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$listingViewModelHash();

  @$internal
  @override
  ListingViewModel create() => ListingViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListingState>(value),
    );
  }
}

String _$listingViewModelHash() => r'a4d033c7b593bea3d7cd018f3c0b37e878713a37';

abstract class _$ListingViewModel extends $Notifier<ListingState> {
  ListingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ListingState, ListingState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ListingState, ListingState>,
        ListingState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
