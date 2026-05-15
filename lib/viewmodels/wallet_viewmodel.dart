import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/providers.dart';
import 'package:unshelf_buyer/services/wallet_service.dart';

part 'wallet_viewmodel.g.dart';

class WalletState {
  const WalletState({
    this.balance = 0.0,
    this.isLoading = false,
    this.errorMessage,
  });

  final double balance;
  final bool isLoading;
  final String? errorMessage;

  WalletState copyWith({
    double? balance,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class WalletViewModel extends _$WalletViewModel {
  @override
  WalletState build() => const WalletState();

  WalletService get _walletService => ref.read(walletServiceProvider);

  Future<void> loadBalance() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final balance = await _walletService.getWalletBalance();
      state = state.copyWith(balance: balance, isLoading: false);
    } catch (e) {
      debugPrint('loadBalance failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load balance: $e',
      );
    }
  }
}
