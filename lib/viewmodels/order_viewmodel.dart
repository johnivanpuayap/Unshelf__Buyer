import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/order_model.dart';

part 'order_viewmodel.g.dart';

class OrderState {
  const OrderState({
    this.orders = const [],
    this.currentStatus = OrderStatus.all,
    this.selectedOrder,
    this.isLoading = false,
    this.paymentIntentData,
  });

  final List<OrderModel> orders;
  final OrderStatus currentStatus;
  final OrderModel? selectedOrder;
  final bool isLoading;
  final Map<String, dynamic>? paymentIntentData;

  List<OrderModel> get filteredOrders {
    if (currentStatus == OrderStatus.all) return orders;
    return orders.where((o) => o.status == currentStatus).toList();
  }

  OrderState copyWith({
    List<OrderModel>? orders,
    OrderStatus? currentStatus,
    OrderModel? selectedOrder,
    bool clearSelectedOrder = false,
    bool? isLoading,
    Map<String, dynamic>? paymentIntentData,
    bool clearPaymentIntent = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      currentStatus: currentStatus ?? this.currentStatus,
      selectedOrder: clearSelectedOrder ? null : selectedOrder ?? this.selectedOrder,
      isLoading: isLoading ?? this.isLoading,
      paymentIntentData:
          clearPaymentIntent ? null : paymentIntentData ?? this.paymentIntentData,
    );
  }
}

@riverpod
class OrderViewModel extends _$OrderViewModel {
  @override
  OrderState build() {
    Future.microtask(() => fetchOrders());
    return const OrderState(isLoading: true);
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('seller_id',
              isEqualTo: FirebaseFirestore.instance.doc('users/${user.uid}'))
          .orderBy('created_at', descending: true)
          .get();

      final orders = await Future.wait<OrderModel>(
          querySnapshot.docs.map((doc) => OrderModel.fetchOrderWithProducts(doc)).toList());

      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      debugPrint('fetchOrders failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  OrderModel? selectOrder(String orderId) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    state = state.copyWith(selectedOrder: order);
    return order;
  }

  void filterOrdersByStatus(String? status) {
    OrderStatus newStatus;
    if (status == null || status == 'All') {
      newStatus = OrderStatus.all;
    } else if (status == 'Pending') {
      newStatus = OrderStatus.pending;
    } else if (status == 'Completed') {
      newStatus = OrderStatus.completed;
    } else if (status == 'Ready') {
      newStatus = OrderStatus.ready;
    } else {
      newStatus = OrderStatus.all;
    }
    state = state.copyWith(currentStatus: newStatus);
  }

  Future<void> makePayment(String amount) async {
    try {
      final intentData = await createPaymentIntent(amount, 'PHP');
      state = state.copyWith(paymentIntentData: intentData);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intentData['client_secret'],
          merchantDisplayName: 'Unshelf',
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
        ),
      );

      await displayPaymentSheet();
    } catch (error) {
      state = state.copyWith(clearPaymentIntent: true);
      debugPrint('makePayment error: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    final secretKey = dotenv.env['stripeSecretKey'] ?? '';
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: {
          'amount': (double.parse(amount).floor() * 100).toString(),
          'currency': currency,
        },
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (error) {
      debugPrint('createPaymentIntent error: $error');
      rethrow;
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      await Stripe.instance.confirmPaymentSheetPayment();
      await updateOrderStatusToPaid();
      state = state.copyWith(clearPaymentIntent: true);
    } catch (error) {
      debugPrint('displayPaymentSheet error: $error');
    }
  }

  Future<void> updateOrderStatusToPaid() async {
    final selected = state.selectedOrder;
    if (selected != null) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(selected.id)
            .update({'is_paid': true});
        selected.is_paid = true;
      } catch (e) {
        debugPrint('updateOrderStatusToPaid error: $e');
      }
    }
  }

  Future<bool> processOrderAndPayment(
    String buyerId,
    List<Map<String, dynamic>> basketItems,
    String sellerId,
    String orderId,
    double totalAmount,
    DateTime? pickupDateTime,
    bool usePoints,
    int points,
  ) async {
    try {
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
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
        'status': 'Pending',
        'subTotal': usePoints ? totalAmount + points : totalAmount,
        'totalPrice': totalAmount,
        'pickupTime': Timestamp.fromDate(pickupDateTime!),
        'pointsDiscount': usePoints ? points : 0,
      });

      await makePayment(totalAmount.toString());
      await orderRef.update({'isPaid': true});

      for (var item in basketItems) {
        final String batchId = item['batchId'];
        final int quantity = item['quantity'];

        final batchSnapshot =
            await FirebaseFirestore.instance.collection('batches').doc(batchId).get();

        if (batchSnapshot.exists) {
          final batchData = batchSnapshot.data() as Map<String, dynamic>?;
          final int currentStock = batchData?['stock'] ?? 0;
          final int newStock = currentStock - quantity;
          if (newStock < 0) throw Exception('Insufficient stock for batch $batchId');
          await FirebaseFirestore.instance
              .collection('batches')
              .doc(batchId)
              .update({'stock': newStock});
        } else {
          final bundleSnapshot =
              await FirebaseFirestore.instance.collection('bundles').doc(batchId).get();
          if (bundleSnapshot.exists) {
            final bundleData = bundleSnapshot.data() as Map<String, dynamic>?;
            final int currentStock = bundleData?['stock'] ?? 0;
            final int newStock = currentStock - quantity;
            if (newStock < 0) throw Exception('Insufficient stock for bundle $batchId');
            await FirebaseFirestore.instance
                .collection('bundles')
                .doc(batchId)
                .update({'stock': newStock});
          }
        }

        await FirebaseFirestore.instance
            .collection('baskets')
            .doc(buyerId)
            .collection('cart_items')
            .doc(batchId)
            .delete();
      }

      return true;
    } catch (e) {
      debugPrint('processOrderAndPayment error: $e');
      return false;
    }
  }
}
