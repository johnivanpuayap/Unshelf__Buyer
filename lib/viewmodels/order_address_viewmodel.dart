import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/providers.dart';

part 'order_address_viewmodel.g.dart';

class OrderAddressState {
  OrderAddressState({
    LatLng? chosenLocation,
    this.mapController,
  }) : chosenLocation = chosenLocation ?? const LatLng(10.3157, 123.8854);

  final LatLng chosenLocation;
  final dynamic mapController; // GoogleMapController — not mock-safe for const

  OrderAddressState copyWith({
    LatLng? chosenLocation,
    dynamic mapController,
  }) {
    return OrderAddressState(
      chosenLocation: chosenLocation ?? this.chosenLocation,
      mapController: mapController ?? this.mapController,
    );
  }
}

@riverpod
class OrderAddressViewModel extends _$OrderAddressViewModel {
  @override
  OrderAddressState build() => OrderAddressState();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  UserRepository get _userRepository => ref.read(userRepositoryProvider);

  void setMapController(dynamic controller) {
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
      // NB: writes lat/lng directly to `orders/{uid}` (the same path is presumably
      // overwritten by every order). Preserved from original behavior — likely a bug.
      await _userRepository.upsertLocation(
        collection: 'orders',
        userId: userId,
        latitude: state.chosenLocation.latitude,
        longitude: state.chosenLocation.longitude,
      );
    } catch (error) {
      throw Exception('Failed to save location: $error');
    }
  }
}
