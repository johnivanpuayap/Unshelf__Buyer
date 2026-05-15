import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unshelf_buyer/services/wallet_service.dart';

class PayMongoService implements WalletService {
  final String _baseUrl =
      'https://api.paymongo.com'; // Replace with actual PayMongo API base URL
  final String _apiKey =
      'pk_test_fGVMd5njs9hDoq48NyS5LjEA'; // Replace with your actual API key

  @override
  Future<double> getWalletBalance() async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/your-endpoint-for-wallet-balance'), // Replace with actual endpoint
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Adjust according to the response structure
      return data['balance']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to load wallet balance');
    }
  }
}
