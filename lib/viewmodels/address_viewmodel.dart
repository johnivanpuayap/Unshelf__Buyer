import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';

class AddressViewmodel extends ChangeNotifier {
  AddressViewmodel({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  GoogleMapController? _mapController;
  LatLng _chosenLocation = const LatLng(10.3157, 123.8854);

  LatLng get chosenLocation => _chosenLocation;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void updateLocation(LatLng location) {
    _chosenLocation = location;
    notifyListeners();
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
        latitude: _chosenLocation.latitude,
        longitude: _chosenLocation.longitude,
      );
    } catch (error) {
      throw Exception('Failed to save location: $error');
    }

    notifyListeners();
  }
}
