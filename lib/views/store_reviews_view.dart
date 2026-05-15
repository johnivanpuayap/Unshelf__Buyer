/// StoreReviewsView — list of reviews for a single store.
///
/// Layout:
///   • AppBar: "{store name} reviews" (fetched async).
///   • Summary card: average star rating + review count.
///   • ListView of ReviewCard widgets (rating stars, reviewer name, date, body).
///   • Empty state when no reviews.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';

class StoreReviewsView extends StatefulWidget {
  const StoreReviewsView({super.key, required this.storeId});

  final String storeId;

  @override
  State<StoreReviewsView> createState() => _StoreReviewsViewState();
}

class _StoreReviewsViewState extends State<StoreReviewsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _storeName;

  @override
  void initState() {
    super.initState();
    _fetchStoreName();
  }

  Future<void> _fetchStoreName() async {
    final snap =
        await _firestore.collection('stores').doc(widget.storeId).get();
    if (mounted && snap.exists) {
      setState(() {
        _storeName = snap.data()?['store_name'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsRef = _firestore
        .collection('stores')
        .doc(widget.storeId)
        .collection('reviews');

    return Scaffold(
      appBar: AppBar(
        title: Text(_storeName != null ? '$_storeName reviews' : 'Reviews'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: reviewsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: EmptyStateView(
                  icon: Icons.error_outline,
                  headline: 'Could not load reviews',
                  body: 'Check your connection and try again.',
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: EmptyStateView(
                  icon: Icons.rate_review_outlined,
                  headline: 'No reviews yet',
                  body: 'Be the first to leave a review for this store.',
                ),
              );
            }

            // Compute summary stats
            double totalRating = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalRating += (data['rating'] as num?)?.toDouble() ?? 0;
            }
            final avgRating = totalRating / docs.length;

            return CustomScrollView(
              slivers: [
                // ── Summary card ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: _RatingSummaryCard(
                      averageRating: avgRating,
                      reviewCount: docs.length,
                    ),
                  ),
                ),

                // ── Review list ───────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReviewCard(
                            rating:
                                (data['rating'] as num?)?.toInt() ?? 0,
                            reviewerName:
                                data['reviewer_name'] as String? ??
                                    data['reviewerName'] as String? ??
                                    'Anonymous',
                            timestamp: (data['created_at'] as Timestamp?)
                                ?.toDate(),
                            body: data['description'] as String? ?? '',
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating summary card
// ---------------------------------------------------------------------------

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.averageRating,
    required this.reviewCount,
  });

  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
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
      child: Row(
        children: [
          // Large rating number
          Text(
            averageRating.toStringAsFixed(1),
            style: tt.displaySmall?.copyWith(color: cs.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StarRow(rating: averageRating.round(), size: 22),
              const SizedBox(height: 4),
              Text(
                '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ReviewCard — extracted component (used here + will be reused in Group D)
// ---------------------------------------------------------------------------

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.rating,
    required this.reviewerName,
    required this.body,
    this.timestamp,
  });

  final int rating;
  final String reviewerName;
  final String body;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer + stars row
          Row(
            children: [
              Expanded(
                child: Text(
                  reviewerName,
                  style: tt.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StarRow(rating: rating, size: 16),
            ],
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(timestamp!),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Star row widget
// ---------------------------------------------------------------------------

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < rating ? cs.tertiary : cs.outline,
          size: size,
        );
      }),
    );
  }
}
