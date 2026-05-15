// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserProfileViewModel)
final userProfileViewModelProvider = UserProfileViewModelProvider._();

final class UserProfileViewModelProvider
    extends $NotifierProvider<UserProfileViewModel, UserProfileState> {
  UserProfileViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userProfileViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userProfileViewModelHash();

  @$internal
  @override
  UserProfileViewModel create() => UserProfileViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileState>(value),
    );
  }
}

String _$userProfileViewModelHash() =>
    r'e168ae7314a5cfec5f552fc36db26d3577fcc29c';

abstract class _$UserProfileViewModel extends $Notifier<UserProfileState> {
  UserProfileState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserProfileState, UserProfileState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<UserProfileState, UserProfileState>,
        UserProfileState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
