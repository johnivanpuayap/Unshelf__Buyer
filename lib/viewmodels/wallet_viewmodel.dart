import 'package:flutter/foundation.dart';
import 'package:unshelf_buyer/services/wallet_service.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel({required WalletService walletService}) : _walletService = walletService;

  final WalletService _walletService;

  double _balance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBalance() async {
    _isLoading = true;
    notifyListeners();
    try {
      _balance = await _walletService.getWalletBalance();
      _errorMessage = null;
    } catch (e) {
      debugPrint('loadBalance failed: $e');
      _errorMessage = 'Failed to load balance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
