import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/services/wallet_service.dart';
import 'package:unshelf_buyer/viewmodels/wallet_viewmodel.dart';

class _MockWalletService extends Mock implements WalletService {}

void main() {
  group('WalletViewModel', () {
    late _MockWalletService mockWallet;
    late WalletViewModel viewModel;

    setUp(() {
      mockWallet = _MockWalletService();
      viewModel = WalletViewModel(walletService: mockWallet);
    });

    test('starts with zero balance and no loading', () {
      expect(viewModel.balance, 0.0);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadBalance populates balance on success', () async {
      when(() => mockWallet.getWalletBalance()).thenAnswer((_) async => 1234.56);

      await viewModel.loadBalance();

      expect(viewModel.balance, 1234.56);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('loadBalance toggles isLoading true then false', () async {
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isLoading));
      when(() => mockWallet.getWalletBalance()).thenAnswer((_) async => 0.0);

      await viewModel.loadBalance();

      expect(states, containsAllInOrder([true, false]));
    });

    test('loadBalance sets errorMessage on failure', () async {
      when(() => mockWallet.getWalletBalance()).thenThrow(Exception('http 500'));

      await viewModel.loadBalance();

      expect(viewModel.errorMessage, contains('Failed to load balance'));
      expect(viewModel.isLoading, isFalse);
    });
  });
}
