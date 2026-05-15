import 'package:unshelf_buyer/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/order_details_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';
import 'package:unshelf_buyer/views/review_view.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({Key? key}) : super(key: key);

  @override
  _OrderTrackingViewState createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  String _statusFilter = 'All'; // Default filter to 'All'

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
        // Fetch batch details from orderItems
        final batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(item['batchId']).get();
        final batchData = batchSnapshot.data();

        if (batchData != null) {
          // Fetch product details from batch
          final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(batchData['productId']).get();
          final productData = productSnapshot.data();

          if (productData != null) {
            // Add the combined batch and product details to the order items list.
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
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), // Increased height for filter row
          child: Column(
            children: [
              Container(
                color: AppColors.lightColor,
                height: 4.0,
              ),
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Pending', 'Ready', 'Cancelled', 'Completed'].map((status) {
                        final isSelected = _statusFilter == status;
                        return GestureDetector(
                          onTap: () => _onFilterChanged(status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
                            margin: const EdgeInsets.only(right: 10.0),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
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
            // Show loading indicator while data is loading
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
              final isDarkBackground = index % 2 == 0;

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
                  final storeName = orderDetails['storeName'];
                  final storeImageUrl = orderDetails['storeImageUrl'] ?? orderDetails['store_image_url'];
                  final isPaid = orderDetails['isPaid'];
                  final status = orderDetails['status'];
                  final isReviewed = orderDetails['isReviewed'];
                  final total = orderDetails['totalPrice'];
                  final pickupTime = orderDetails['pickupTime'];
                  final pickupCode = orderDetails['pickupCode'];
                  final createdAt = orderDetails['createdAt'];

                  Color statusColor;
                  switch (status) {
                    case 'Pending':
                      statusColor = Colors.orange;
                      break;
                    case 'Cancelled':
                      statusColor = Colors.red;
                      break;
                    case 'Ready':
                      statusColor = Colors.green;
                      break;
                    case 'Completed':
                      statusColor = Colors.green;
                      break;
                    default:
                      statusColor = Colors.grey;
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
                      color: isDarkBackground ? Colors.grey[200] : Colors.grey[100],
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Order Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ID: ${orderDetails['orderId']}',
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      createdAt.toString().split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: statusColor, // Use color based on status
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₱ ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      // Show Review Button for Completed Orders
                                      if (status == 'Completed')
                                        if (isReviewed == 'true')
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(255, 138, 255, 191),
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: const Text(
                                              'Reviewed',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black,
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
                                                    storeId: orderDetails['storeId'], // Assuming storeId is available
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(255, 255, 255, 138),
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: const Text(
                                                '+ Review',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color.fromARGB(255, 250, 134, 0),
                                                ),
                                              ),
                                            ),
                                          ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      // Container(
                                      //   padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                      //   decoration: BoxDecoration(
                                      //     color: isPaid ? AppColors.primaryColor : Colors.red,
                                      //     borderRadius: BorderRadius.circular(12.0),
                                      //   ),
                                      //   child: Text(
                                      //     isPaid ? 'Paid' : 'Unpaid',
                                      //     style: const TextStyle(
                                      //       fontSize: 12.0,
                                      //       color: Colors.white,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
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
