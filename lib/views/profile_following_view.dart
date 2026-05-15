import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/store_card.dart';

class FollowingView extends StatelessWidget {
  const FollowingView({super.key});

  Future<void> _unfollow(BuildContext context, String storeId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(storeId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from following')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('following');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Following', style: tt.titleLarge),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: followingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: EmptyStateView(
                icon: Icons.storefront_outlined,
                headline: 'Not following any stores yet',
                body:
                    'Tap the follow button on any store to follow it.',
              ),
            );
          }

          final storeDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: storeDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final storeId = storeDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('stores')
                    .doc(storeId)
                    .get(),
                builder: (context, storeSnap) {
                  if (storeSnap.connectionState ==
                      ConnectionState.waiting) {
                    return _StoreCardSkeleton(cs: cs);
                  }

                  if (!storeSnap.hasData ||
                      !storeSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final data =
                      storeSnap.data!.data() as Map<String, dynamic>;
                  final storeName =
                      (data['store_name'] as String?) ?? 'Unknown store';
                  final imageUrl = data['store_image_url'] as String?;
                  final rating = (data['rating'] as num?)?.toDouble();
                  final followers =
                      (data['follower_count'] as num?)?.toInt();

                  return Row(
                    children: [
                      Expanded(
                        child: StoreCard(
                          storeId: storeId,
                          storeName: storeName,
                          storeImageUrl: imageUrl,
                          rating: rating,
                          followerCount: followers,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unfollow button
                      OutlinedButton(
                        onPressed: () => _unfollow(context, storeId),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                              color: cs.outline.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Unfollow',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StoreCardSkeleton extends StatelessWidget {
  const _StoreCardSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
