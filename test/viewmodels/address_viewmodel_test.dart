import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/providers.dart';
import 'package:unshelf_buyer/viewmodels/address_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('AddressViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockUserRepository mockUsers;

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockUsers = _MockUserRepository();
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
        userRepositoryProvider.overrideWithValue(mockUsers),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('default chosenLocation is Cebu City', () {
      final container = makeContainer();
      final state = container.read(addressViewModelProvider);
      expect(state.chosenLocation.latitude, 10.3157);
      expect(state.chosenLocation.longitude, 123.8854);
    });

    test('updateLocation mutates state and notifies', () {
      final container = makeContainer();
      var notified = false;
      container.listen(addressViewModelProvider, (_, __) => notified = true);

      container.read(addressViewModelProvider.notifier).updateLocation(const LatLng(14.5995, 120.9842));

      expect(container.read(addressViewModelProvider).chosenLocation, const LatLng(14.5995, 120.9842));
      expect(notified, isTrue);
    });

    group('saveLocation', () {
      test('throws when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);
        final container = makeContainer();

        await expectLater(
          container.read(addressViewModelProvider.notifier).saveLocation(),
          throwsException,
        );
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
        final container = makeContainer();
        container.read(addressViewModelProvider.notifier).updateLocation(const LatLng(1.0, 2.0));

        await container.read(addressViewModelProvider.notifier).saveLocation();

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
        final container = makeContainer();

        await expectLater(
          container.read(addressViewModelProvider.notifier).saveLocation(),
          throwsException,
        );
      });
    });
  });
}
