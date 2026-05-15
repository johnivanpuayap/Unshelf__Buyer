import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    final orderData = orderSnapshot.data();

    if (orderData != null) {
      final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(orderData['sellerId']).get();
      final storeData = storeSnapshot.data();

      final List<Map<String?, dynamic>> orderItemsDetails = [];

      for (var item in orderData['orderItems']) {
        final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(item['productId']).get();
        final productData = productSnapshot.data();

        if (productData != null) {
          orderItemsDetails.add({
            'name': productData['name'],
            'price': productData['price'],
            'mainImageUrl': productData['mainImageUrl'],
            'quantity': item['quantity'],
            'quantifier': productData['quantifier'],
          });
        } else {}
      }

      // Here, we ensure that the total is returned as an int by using .toInt()
      final int total = orderItemsDetails.fold<num>(0, (sum, item) => sum + item['price'] * item['quantity']).toInt();

      return {
        'storeName': storeData?['store_name'] ?? '',
        'storeImageUrl': storeData?['store_image_url'] ?? '',
        'orderItems': orderItemsDetails,
        'createdAt': orderData['createdAt'].toDate(),
        'totalPrice': orderData['totalPrice'],
        'pickupTime': orderData['pickupTime'],
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
          "Order History",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: _auth.currentUser!.uid)
            .where('status', isEqualTo: 'Completed')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orderDetails = orderSnapshot.data!;
                  final storeName = orderDetails['storeName'];
                  final storeImageUrl = orderDetails['storeImageUrl'];
                  final total = orderDetails['totalPrice'];
                  final pickupTime = orderDetails['pickupTime'];
                  final orderItems = orderDetails['orderItems'];
                  final createdAt = orderDetails['createdAt'];

                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(storeImageUrl),
                          ),
                          title: Text(storeName, style: tt.titleMedium),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          subtitle: Text(
                            "Ordered On: $createdAt\nPickup Time: $pickupTime",
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                        const Divider(height: 1),
                        ...orderItems.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item['mainImageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'PHP ${item['price']} / ${item['quantifier']}',
                                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                                      ),
                                      Text(
                                        'x${item['quantity']}',
                                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Total: ₱${total.toStringAsFixed(2)}",
                                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 8, color: cs.surfaceContainerHighest),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Near Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

void _onItemTapped(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return HomeView();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return MapPage();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return ProfileView();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
  }
}
