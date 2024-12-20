import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unshelf_buyer/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class OrderViewModel extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderStatus _currentStatus = OrderStatus.all;
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  Map<String, dynamic>? paymentIntentData;

  OrderModel? get selectedOrder => _selectedOrder;
  List<OrderModel> get orders => _orders;
  OrderStatus get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;

  late Future<void> fetchOrdersFuture;

  OrderViewModel() {
    fetchOrdersFuture = fetchOrders();
  }

  List<OrderModel> get filteredOrders {
    if (_currentStatus == OrderStatus.all) {
      return _orders;
    }
    return _orders.where((order) => order.status == _currentStatus).toList();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('seller_id', isEqualTo: FirebaseFirestore.instance.doc('users/${user.uid}'))
          .orderBy('created_at', descending: true)
          .get();

      _orders = await Future.wait<OrderModel>(querySnapshot.docs.map((doc) => OrderModel.fetchOrderWithProducts(doc)).toList());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Failed to fetch orders: $e');
    }
  }

  OrderModel? selectOrder(String orderId) {
    _isLoading = true;
    _selectedOrder = _orders.firstWhere((order) => order.id == orderId);
    _isLoading = false;
    notifyListeners();
    return _selectedOrder;
  }

  void filterOrdersByStatus(String? status) {
    if (status == null || status == 'All') {
      _currentStatus = OrderStatus.all;
    } else if (status == 'Pending') {
      _currentStatus = OrderStatus.pending;
    } else if (status == 'Completed') {
      _currentStatus = OrderStatus.completed;
    } else if (status == 'Ready') {
      _currentStatus = OrderStatus.ready;
    }
    notifyListeners();
  }

  // Function to initiate payment process
  Future<void> makePayment(String amount) async {
    try {
      paymentIntentData = await createPaymentIntent(amount, 'PHP');

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          merchantDisplayName: 'Unshelf',
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
        ),
      );

      // Display payment sheet
      await displayPaymentSheet();
    } catch (error) {
      paymentIntentData = null;
      print('Error in makePayment: $error');
      rethrow;
    }
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    String secretKey = dotenv.env['stripeSecretKey'] ?? '';
    try {
      Map<String, dynamic> body = {
        'amount': (double.parse(amount).floor() * 100).toString(), // Amount in cents
        'currency': currency,
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer ${secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      ("Payment Intent Response: ${response.body}");
      return json.decode(response.body);
    } catch (error) {
      print('Error in createPaymentIntent: $error');
      rethrow;
    }
  }

  // Display the Stripe payment sheet
  Future<void> displayPaymentSheet() async {
    try {
      ("inside displayPaymentSheet - start");

      await Stripe.instance.presentPaymentSheet().then((value) {
        ("inside displayPaymentSheet - present");
      }).catchError((error) {
        ("Error presenting payment sheet: $error");
      });

      await Stripe.instance.confirmPaymentSheetPayment().then((value) {
        ("inside displayPaymentSheet - confirm");
      }).catchError((error) {
        ("Error confirming payment: $error");
      });

      // Update order status to 'paid' once the payment is successful
      await updateOrderStatusToPaid();

      ("inside displayPaymentSheet - updated");
      paymentIntentData = null;
      notifyListeners();
    } catch (error) {
      ('Error in displayPaymentSheet: $error');
    }
  }

  // Update the order status to "Paid"
  Future<void> updateOrderStatusToPaid() async {
    if (_selectedOrder != null) {
      try {
        // Update order status in Firestore
        await FirebaseFirestore.instance.collection('orders').doc(_selectedOrder!.id).update({
          'is_paid': true,
        });

        // Update locally as well
        _selectedOrder!.is_paid = true;
        notifyListeners();
      } catch (e) {
        print('Error updating order status: $e');
      }
    }
  }

  // New method to handle the full order process
  Future<bool> processOrderAndPayment(String buyerId, List<Map<String, dynamic>> basketItems, String sellerId, String orderId,
      double totalAmount, DateTime? pickupDateTime, bool usePoints, int points) async {
    try {
      // Add order to firestore
      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'buyerId': buyerId,
        'completedAt': null,
        'createdAt': DateTime.now(),
        'isPaid': false,
        'orderId': orderId,
        'orderItems': basketItems
            .map((item) => {
                  'batchId': item['batchId'],
                  'quantity': item['quantity'],
                  'price': item['batchPrice'],
                  'isBundle': item['isBundle'],
                })
            .toList(),
        'sellerId': sellerId,
        'status': "Pending",
        'subTotal': usePoints ? totalAmount + points : totalAmount,
        'totalPrice': totalAmount,
        'pickupTime': Timestamp.fromDate(pickupDateTime!),
        'pointsDiscount': usePoints ? points : 0
      });

      // Process the payment
      await makePayment(totalAmount.toString());

      // If payment is successful, mark order as paid
      await orderRef.update({'isPaid': true});

      // Remove items from user's basket
      for (var item in basketItems) {
        String batchId = item['batchId'];
        int quantity = item['quantity'];

        // Fetch the batch document if batch
        DocumentSnapshot batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(batchId).get();

        if (batchSnapshot.exists) {
          Map<String, dynamic>? batchData = batchSnapshot.data() as Map<String, dynamic>?;
          int currentStock = batchData?['stock'] ?? 0;
          // Update the stock for the batch
          int newStock = currentStock - quantity;
          if (newStock < 0) {
            throw Exception('Insufficient stokk for batch $batchId');
          }
          await FirebaseFirestore.instance.collection('batches').doc(batchId).update({'stock': newStock});
        } else {
          DocumentSnapshot bundleSnapshot = await FirebaseFirestore.instance.collection('bundles').doc(batchId).get();
          if (bundleSnapshot.exists) {
            Map<String, dynamic>? bundleData = bundleSnapshot.data() as Map<String, dynamic>?;
            int currentStock = bundleData?['stock'] ?? 0;
            // Update the stock for the batch
            int newStock = currentStock - quantity;
            if (newStock < 0) {
              throw Exception('Insufficient stock for bundle $batchId');
            }
            await FirebaseFirestore.instance.collection('bundles').doc(batchId).update({'stock': newStock});
          }
        }

        // Remove the item from the user's cart
        await FirebaseFirestore.instance.collection('baskets').doc(buyerId).collection('cart_items').doc(batchId).delete();
      }

      return true;
    } catch (e) {
      print('Error during order and payment process: $e');
      return false;
    }
  }
}
