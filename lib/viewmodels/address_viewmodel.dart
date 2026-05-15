import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/providers.dart';

part 'address_viewmodel.g.dart';

class AddressState {
  AddressState({
    LatLng? chosenLocation,
    this.mapController,
  }) : chosenLocation = chosenLocation ?? const LatLng(10.3157, 123.8854);

  final LatLng chosenLocation;
  final GoogleMapController? mapController;

  AddressState copyWith({
    LatLng? chosenLocation,
    GoogleMapController? mapController,
  }) {
    return AddressState(
      chosenLocation: chosenLocation ?? this.chosenLocation,
      mapController: mapController ?? this.mapController,
    );
  }
}

@riverpod
class AddressViewModel extends _$AddressViewModel {
  @override
  AddressState build() => AddressState();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  UserRepository get _userRepository => ref.read(userRepositoryProvider);

  void setMapController(GoogleMapController controller) {
    state = state.copyWith(mapController: controller);
  }

  void updateLocation(LatLng location) {
    state = state.copyWith(chosenLocation: location);
  }

  Future<void> saveLocation() async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    try {
      // NB: writes into `stores/{uid}` even though this is the buyer app — preserved
      // behavior. Flagged for separate review (likely should be `users/{uid}`).
      await _userRepository.upsertLocation(
        collection: 'stores',
        userId: userId,
        latitude: state.chosenLocation.latitude,
        longitude: state.chosenLocation.longitude,
      );
    } catch (error) {
      throw Exception('Failed to save location: $error');
    }
  }
}
