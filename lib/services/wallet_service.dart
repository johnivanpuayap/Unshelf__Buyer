/// Abstraction over the third-party wallet-balance source (PayMongo today).
abstract class WalletService {
  /// Returns the current wallet balance in the merchant's account currency.
  /// Throws if the upstream call fails or returns a non-2xx status.
  Future<double> getWalletBalance();
}
