/// StoresView — full directory of all stores on Unshelf.
///
/// Layout: AppBar ("Stores") + "Near Me" action → MapPage.
/// Body: stream of all stores rendered as [StoreCard] in a 2-column grid.
/// Empty: EmptyStateView when no stores are available.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/store_card.dart';
import 'package:unshelf_buyer/views/map_view.dart';

class StoresView extends StatelessWidget {
  const StoresView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapPage()),
            ),
            icon: Icon(Icons.place_outlined, color: cs.primary),
            label: Text(
              'Near Me',
              style: TextStyle(color: cs.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: EmptyStateView(
                  icon: Icons.error_outline,
                  headline: 'Could not load stores',
                  body: 'Check your connection and try again.',
                  ctaLabel: 'Try again',
                  onCta: () {},
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: EmptyStateView(
                  icon: Icons.store_outlined,
                  headline: 'No stores yet',
                  body: 'Stores will appear here as they join Unshelf.',
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final storeId = docs[index].id;

                return StoreCard(
                  storeId: storeId,
                  storeName: data['store_name'] as String? ?? 'Unnamed store',
                  storeImageUrl: data['store_image_url'] as String? ??
                      data['storeImageUrl'] as String?,
                  rating: (data['rating'] as num?)?.toDouble(),
                  followerCount: data['follower_count'] as int?,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
