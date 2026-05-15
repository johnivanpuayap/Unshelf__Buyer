import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/viewmodels/address_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('AddressViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockUserRepository mockUsers;
    late AddressViewModel viewModel;

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockUsers = _MockUserRepository();
      viewModel = AddressViewModel(authRepository: mockAuth, userRepository: mockUsers);
    });

    test('default chosenLocation is Cebu City', () {
      expect(viewModel.chosenLocation.latitude, 10.3157);
      expect(viewModel.chosenLocation.longitude, 123.8854);
    });

    test('updateLocation mutates state and notifies', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.updateLocation(const LatLng(14.5995, 120.9842));

      expect(viewModel.chosenLocation, const LatLng(14.5995, 120.9842));
      expect(notified, isTrue);
    });

    group('saveLocation', () {
      test('throws when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);

        await expectLater(viewModel.saveLocation(), throwsException);
        verifyNever(() => mockUsers.upsertLocation(
              collection: any(named: 'collection'),
              userId: any(named: 'userId'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            ));
      });

      test('writes lat/lng to stores/{uid} with merge semantics', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.upsertLocation(
              collection: any(named: 'collection'),
              userId: any(named: 'userId'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            )).thenAnswer((_) async {});
        viewModel.updateLocation(const LatLng(1.0, 2.0));

        await viewModel.saveLocation();

        verify(() => mockUsers.upsertLocation(
              collection: 'stores',
              userId: 'uid-1',
              latitude: 1.0,
              longitude: 2.0,
            )).called(1);
      });

      test('rethrows wrapped exception when repository fails', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.upsertLocation(
              collection: any(named: 'collection'),
              userId: any(named: 'userId'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            )).thenThrow(Exception('permission denied'));

        await expectLater(viewModel.saveLocation(), throwsException);
      });
    });
  });
}
