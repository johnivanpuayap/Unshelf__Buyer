/// OrderHistoryView — tabbed order history: Active / Completed / Cancelled.
///
/// Layout:
///   • AppBar: back + "Your orders"
///   • TabBar: Active | Completed | Cancelled (primary green active state)
///   • TabBarView: list of OrderCard per tab, with EmptyStateView per tab
///   • Loading + error states
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/order_card.dart';
import 'package:unshelf_buyer/views/order_details_view.dart';

// ─── Active statuses ──────────────────────────────────────────────────────────

const _activeStatuses = ['Pending', 'Confirmed', 'Preparing', 'Ready'];
const _completedStatuses = ['Completed'];
const _cancelledStatuses = ['Cancelled'];

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: _OrderHistoryScaffold(),
    );
  }
}

class _OrderHistoryScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          'Your orders',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
        bottom: TabBar(
          indicatorColor: cs.onPrimary,
          indicatorWeight: 3,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.55),
          labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: tt.labelLarge,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _OrderTab(statuses: _activeStatuses),
          _OrderTab(statuses: _completedStatuses),
          _OrderTab(statuses: _cancelledStatuses),
        ],
      ),
    );
  }
}

// ─── Single tab ───────────────────────────────────────────────────────────────

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.statuses});
  final List<String> statuses;

  String get _emptyHeadline {
    if (statuses.contains('Pending')) return 'No active orders';
    if (statuses.contains('Completed')) return 'No completed orders';
    return 'No cancelled orders';
  }

  String get _emptyBody {
    if (statuses.contains('Pending')) {
      return 'Orders you place will appear here.';
    }
    if (statuses.contains('Completed')) {
      return 'Completed orders will appear here.';
    }
    return 'Cancelled orders will appear here.';
  }

  IconData get _emptyIcon {
    if (statuses.contains('Pending')) return Icons.receipt_long_outlined;
    if (statuses.contains('Completed')) return Icons.check_circle_outline;
    return Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.lock_outline,
          headline: 'Not signed in',
          body: 'Sign in to view your orders.',
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .where('status', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: EmptyStateView(
              icon: Icons.error_outline,
              headline: 'Something went wrong',
              body: snapshot.error.toString(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: EmptyStateView(
              icon: _emptyIcon,
              headline: _emptyHeadline,
              body: _emptyBody,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemBuilder: (context, index) {
            return _OrderCardLoader(doc: docs[index]);
          },
        );
      },
    );
  }
}

// ─── Per-order async loader ───────────────────────────────────────────────────

class _OrderCardLoader extends StatelessWidget {
  const _OrderCardLoader({required this.doc});
  final DocumentSnapshot doc;

  Future<Map<String, dynamic>> _fetchDetails() async {
    final data = doc.data() as Map<String, dynamic>;

    final storeSnap = await FirebaseFirestore.instance
        .collection('stores')
        .doc(data['sellerId'] as String?)
        .get();
    final storeData = storeSnap.data();

    final List<Map<String, dynamic>> items = [];
    for (final item
        in (data['orderItems'] as List<dynamic>? ?? [])) {
      final batchSnap = await FirebaseFirestore.instance
          .collection('batches')
          .doc(item['batchId'] as String?)
          .get();
      final batchData = batchSnap.data();
      if (batchData != null) {
        final productSnap = await FirebaseFirestore.instance
            .collection('products')
            .doc(batchData['productId'] as String?)
            .get();
        final productData = productSnap.data();
        if (productData != null) {
          items.add({
            'name': productData['name'] ?? '',
            'price': batchData['price'] ?? 0.0,
            'mainImageUrl': productData['mainImageUrl'] ?? '',
            'quantity': item['quantity'] ?? 1,
            'quantifier': productData['quantifier'] ?? '',
            'batchDiscount': batchData['discount'],
            'expiryDate': batchData['expiryDate'],
          });
        }
      }
    }

    return {
      'storeName': storeData?['store_name'] ?? '',
      'storeImageUrl':
          storeData?['store_image_url'] ?? storeData?['storeImageUrl'] ?? '',
      'storeId': data['sellerId'] ?? '',
      'docId': doc.id,
      'orderId': data['orderId'] ?? doc.id,
      'orderItems': items,
      'status': data['status'] ?? '',
      'isPaid': data['isPaid'] ?? false,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'cancelledAt': data['cancelledAt'],
      'completedAt': data['completedAt'],
      'totalPrice': (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      'pickupTime': (data['pickupTime'] as Timestamp?)?.toDate(),
      'pickupCode': data['pickupCode'] ?? '...',
      'isReviewed': (data['isReviewed'] ?? false).toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final d = snapshot.data!;
        final items = d['orderItems'] as List<Map<String, dynamic>>;

        return OrderCard(
          storeImageUrl: d['storeImageUrl'] as String,
          storeName: d['storeName'] as String,
          orderId: d['orderId'] as String,
          status: d['status'] as String,
          itemCount: items.length,
          totalPrice: d['totalPrice'] as double,
          createdAt: d['createdAt'] as DateTime,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsView(orderDetails: d),
              ),
            );
          },
        );
      },
    );
  }
}
