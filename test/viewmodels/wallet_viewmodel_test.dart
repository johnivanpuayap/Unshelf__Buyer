import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/providers.dart';
import 'package:unshelf_buyer/services/wallet_service.dart';
import 'package:unshelf_buyer/viewmodels/wallet_viewmodel.dart';

class _MockWalletService extends Mock implements WalletService {}

void main() {
  group('WalletViewModel', () {
    late _MockWalletService mockWallet;

    setUp(() {
      mockWallet = _MockWalletService();
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        walletServiceProvider.overrideWithValue(mockWallet),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('starts with zero balance and no loading', () {
      final container = makeContainer();
      final state = container.read(walletViewModelProvider);
      expect(state.balance, 0.0);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('loadBalance populates balance on success', () async {
      when(() => mockWallet.getWalletBalance()).thenAnswer((_) async => 1234.56);
      final container = makeContainer();

      await container.read(walletViewModelProvider.notifier).loadBalance();

      final state = container.read(walletViewModelProvider);
      expect(state.balance, 1234.56);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('loadBalance sets isLoading true then false', () async {
      when(() => mockWallet.getWalletBalance()).thenAnswer((_) async => 0.0);
      final container = makeContainer();

      final states = <bool>[];
      container.listen(
        walletViewModelProvider.select((s) => s.isLoading),
        (_, next) => states.add(next),
      );

      await container.read(walletViewModelProvider.notifier).loadBalance();

      expect(states, containsAllInOrder([true, false]));
    });

    test('loadBalance sets errorMessage on failure', () async {
      when(() => mockWallet.getWalletBalance()).thenThrow(Exception('http 500'));
      final container = makeContainer();

      await container.read(walletViewModelProvider.notifier).loadBalance();

      final state = container.read(walletViewModelProvider);
      expect(state.errorMessage, contains('Failed to load balance'));
      expect(state.isLoading, isFalse);
    });
  });
}
