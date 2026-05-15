import 'package:unshelf_buyer/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class OrderDetailsView extends StatefulWidget {
  final Map<String?, dynamic> orderDetails;

  const OrderDetailsView({super.key, required this.orderDetails});

  @override
  _OrderDetailsViewState createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _cancelOrder() async {
    try {
      ('? ${widget.orderDetails['orderId']}');
      await _firestore.collection('orders').doc(widget.orderDetails['docId']).update({'status': 'Cancelled'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order has been canceled successfully."),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel order: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Order Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25.0,
          ),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: AppColors.lightColor,
              height: 6.0,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: SingleChildScrollView(
          // Wrap everything in SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreView(storeId: widget.orderDetails['storeId']),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Store Image
                      Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: widget.orderDetails['storeImageUrl'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),

                      // Store Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.orderDetails['storeName'] ?? 'Unknown', // Store Name
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     // Store Image
              //     Container(
              //       width: 100,
              //       height: 80,
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(10),
              //         boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
              //       ),
              //       child: ClipRRect(
              //         borderRadius: BorderRadius.circular(10),
              //         child: CachedNetworkImage(
              //           imageUrl: widget.orderDetails['storeImageUrl'] ?? '',
              //           fit: BoxFit.cover,
              //           placeholder: (context, url) => const CircularProgressIndicator(),
              //           errorWidget: (context, url, error) => const Icon(Icons.error),
              //         ),
              //       ),
              //     ),
              //     const SizedBox(width: 30),

              //     // Store Details
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             widget.orderDetails['storeName'] ?? '', // Store Name
              //             style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
              //           ),
              //           const SizedBox(height: 4),
              //         ],
              //       ),
              //     ), // Heart button (Remove from following)
              //     // IconButton(
              //     //   icon: const Icon(Icons.favorite, color: AppColors.primaryColor),
              //     //   onPressed: () {
              //     //     _removeFromFollowing(storeId);
              //     //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              //     //       content: Text('Successfully removed from following list.'),
              //     //     ));
              //     //   },
              //     // ),
              //   ],
              // ),
              // Order Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300), // Border color
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: ${widget.orderDetails['orderId']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order Date: ${DateFormat('yyyy-MM-dd').format(widget.orderDetails['createdAt'])}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Pickup Time: ${DateFormat('yyyy-MM-dd hh:mm a').format(widget.orderDetails['pickupTime']!)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Price: ₱${widget.orderDetails['totalPrice'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Box for Order Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            border: Border.all(
                              color: Colors.black, // Border color
                              width: 1.0, // Border width
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.orderDetails['status'],
                            style: const TextStyle(
                              fontSize: 14.0, // Font size for the text
                              color: Colors.black, // Text color
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Space between the boxes

                        // Box for Paid or Not Paid
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.orderDetails['isPaid'] ? AppColors.primaryColor : Colors.red,
                            border: Border.all(
                              color: Colors.black, // Border color
                              width: 1.0, // Border width
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.orderDetails['isPaid'] ? 'Paid' : 'Not Paid',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white, // White text for clarity
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Products List
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              // Products List View (no Expanded around it)
              ListView.builder(
                itemCount: widget.orderDetails['orderItems'].length,
                shrinkWrap: true, // Important for ListView inside scrollable widget
                physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          child: Image.network(
                            widget.orderDetails['orderItems'][index]['mainImageUrl'],
                            width: 80, // Reduced the size of the image
                            height: 80, // Reduced the size of the image
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.orderDetails['orderItems'][index]['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        // Spacer for right-alignment
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'x ${widget.orderDetails['orderItems'][index]['quantity']} ${widget.orderDetails['orderItems'][index]['quantifier']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Order Details Section

              if (widget.orderDetails['status'] == 'Ready') ...[
                _buildDetailRow('Pickup Code', widget.orderDetails['pickupCode']!),
                if (!widget.orderDetails['isPaid']) ...[
                  _buildDetailRow('Payment', widget.orderDetails['totalPrice'].toStringAsFixed(2)),
                ],
              ] else if (widget.orderDetails['status'] == 'Completed') ...[
                _buildDetailRow(
                    'Completed At', DateFormat('yyyy-MM-dd HH:mm').format(widget.orderDetails['completedAt']!.toDate())),
              ] else if (widget.orderDetails['status'] == 'Cancelled') ...[
                _buildDetailRow(
                    'Cancelled At', DateFormat('yyyy-MM-dd HH:mm').format(widget.orderDetails['cancelledAt']!.toDate())),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.orderDetails['status'] == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Cancel Order'),
                              content: const Text('Are you sure you want to cancel this order?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close dialog
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _cancelOrder();

                                    Navigator.of(context).pop(); // Close dialog
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
