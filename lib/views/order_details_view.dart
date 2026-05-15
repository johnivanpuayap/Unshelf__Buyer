import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
        SnackBar(
          content: const Text("Order has been canceled successfully."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel order: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Order Details",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: cs.secondary,
            height: 4.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
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
                      Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              offset: const Offset(0, 1),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color(0xFF1F2A20).withValues(alpha: 0.06),
                              offset: const Offset(0, 8),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: widget.orderDetails['storeImageUrl'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.orderDetails['storeName'] ?? 'Unknown',
                              style: tt.titleMedium,
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Order Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: ${widget.orderDetails['orderId']}',
                      style: tt.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order Date: ${DateFormat('yyyy-MM-dd').format(widget.orderDetails['createdAt'])}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    Text(
                      'Pickup Time: ${DateFormat('yyyy-MM-dd hh:mm a').format(widget.orderDetails['pickupTime']!)}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Price: ₱${widget.orderDetails['totalPrice'].toStringAsFixed(2)}',
                      style: tt.titleMedium?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.orderDetails['status'],
                            style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Paid badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.orderDetails['isPaid'] ? cs.primaryContainer : cs.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.orderDetails['isPaid'] ? 'Paid' : 'Not Paid',
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.orderDetails['isPaid'] ? cs.onPrimaryContainer : cs.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Products',
                style: tt.titleMedium,
              ),
              const SizedBox(height: 10),
              ListView.builder(
                itemCount: widget.orderDetails['orderItems'].length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                          child: Image.network(
                            widget.orderDetails['orderItems'][index]['mainImageUrl'],
                            width: 80,
                            height: 80,
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
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'x ${widget.orderDetails['orderItems'][index]['quantity']} ${widget.orderDetails['orderItems'][index]['quantifier']}',
                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (widget.orderDetails['status'] == 'Ready') ...[
                _buildDetailRow(context, 'Pickup Code', widget.orderDetails['pickupCode']!),
                if (!widget.orderDetails['isPaid']) ...[
                  _buildDetailRow(context, 'Payment', widget.orderDetails['totalPrice'].toStringAsFixed(2)),
                ],
              ] else if (widget.orderDetails['status'] == 'Completed') ...[
                _buildDetailRow(
                    context, 'Completed At', DateFormat('yyyy-MM-dd HH:mm').format(widget.orderDetails['completedAt']!.toDate())),
              ] else if (widget.orderDetails['status'] == 'Cancelled') ...[
                _buildDetailRow(
                    context, 'Cancelled At', DateFormat('yyyy-MM-dd HH:mm').format(widget.orderDetails['cancelledAt']!.toDate())),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _cancelOrder();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Cancel Order',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onError,
                            ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
