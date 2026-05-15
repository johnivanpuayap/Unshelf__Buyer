import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/views/order_details_view.dart';
import 'package:unshelf_buyer/views/review_view.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({Key? key}) : super(key: key);

  @override
  _OrderTrackingViewState createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  String _statusFilter = 'All';

  void _onFilterChanged(String newStatus) {
    setState(() {
      _statusFilter = newStatus;
    });
  }

  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    final orderData = orderSnapshot.data();

    if (orderData != null) {
      final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(orderData['sellerId']).get();
      final storeData = storeSnapshot.data();

      final List<Map<String?, dynamic>> orderItemsDetails = [];
      for (var item in orderData['orderItems']) {
        final batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(item['batchId']).get();
        final batchData = batchSnapshot.data();

        if (batchData != null) {
          final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(batchData['productId']).get();
          final productData = productSnapshot.data();

          if (productData != null) {
            orderItemsDetails.add({
              'name': productData['name'],
              'price': batchData['price'],
              'mainImageUrl': productData['mainImageUrl'] ?? '',
              'quantity': item['quantity'],
              'quantifier': productData['quantifier'],
              'batchDiscount': batchData['discount'],
              'expiryDate': batchData['expiryDate'],
            });
          }
        }
      }

      return {
        'storeName': storeData?['store_name'] ?? '',
        'storeImageUrl': storeData?['store_image_url'] ?? storeData?['storeImageUrl'],
        'storeId': orderData['sellerId'],
        'docId': orderId,
        'orderId': orderData['orderId'],
        'orderItems': orderItemsDetails,
        'status': orderData['status'],
        'isPaid': orderData['isPaid'],
        'createdAt': orderData['createdAt'].toDate(),
        'cancelledAt': orderData['cancelledAt'] ?? null,
        'completedAt': orderData['completedAt'] ?? null,
        'totalPrice': orderData['totalPrice'],
        'pickupTime': orderData['pickupTime'].toDate(),
        'pickupCode': orderData['pickupCode'] ?? '...',
        'isReviewed': orderData['isReviewed'].toString() ?? 'false',
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "My Orders",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              Container(color: cs.secondary, height: 4.0),
              Container(
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Pending', 'Ready', 'Cancelled', 'Completed'].map((status) {
                        final isSelected = _statusFilter == status;
                        return GestureDetector(
                          onTap: () => _onFilterChanged(status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
                            margin: const EdgeInsets.only(right: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              status,
                              style: tt.bodySmall?.copyWith(
                                color: isSelected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: _auth.currentUser!.uid)
            .where('status', isEqualTo: _statusFilter == 'All' ? null : _statusFilter)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderId = orders[index].id;

              return FutureBuilder<Map<String?, dynamic>>(
                future: fetchOrderDetails(orderId),
                builder: (context, orderSnapshot) {
                  if (!orderSnapshot.hasData) {
                    return const Center(
                      heightFactor: 2,
                      child: CircularProgressIndicator(),
                    );
                  }

                  final orderDetails = orderSnapshot.data!;
                  final status = orderDetails['status'];
                  final isReviewed = orderDetails['isReviewed'];
                  final total = orderDetails['totalPrice'];
                  final createdAt = orderDetails['createdAt'];

                  Color statusColor;
                  switch (status) {
                    case 'Pending':
                      statusColor = Colors.orange;
                      break;
                    case 'Cancelled':
                      statusColor = cs.error;
                      break;
                    case 'Ready':
                    case 'Completed':
                      statusColor = cs.primary;
                      break;
                    default:
                      statusColor = cs.onSurface.withValues(alpha: 0.4);
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsView(orderDetails: orderDetails),
                        ),
                      );
                    },
                    child: Container(
                      color: index.isEven ? cs.surfaceContainerHighest : cs.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ID: ${orderDetails['orderId']}',
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  createdAt.toString().split(' ')[0],
                                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Status: $status',
                                  style: tt.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₱ ${total.toStringAsFixed(2)}',
                                style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  if (status == 'Completed')
                                    if (isReviewed == 'true')
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        child: Text(
                                          'Reviewed',
                                          style: tt.bodySmall?.copyWith(
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReviewPage(
                                                orderDocId: orderId,
                                                orderId: orderDetails['orderId'],
                                                storeId: orderDetails['storeId'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                          decoration: BoxDecoration(
                                            color: cs.secondaryContainer,
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: Text(
                                            '+ Review',
                                            style: tt.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }
}
