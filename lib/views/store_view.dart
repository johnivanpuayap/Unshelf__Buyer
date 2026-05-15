/// StoreView — single-store detail screen.
///
/// Layout:
///   • Hero header: large cover image (or gradient placeholder) with store name
///     overlay, follow button, and chat button.
///   • Info row: rating, follower count, location button.
///   • Tab bar: "Listings" (2-col ProductCard.compact grid) | "Reviews" (link
///     to StoreReviewsView).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/product_card.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';
import 'package:unshelf_buyer/views/chat_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/store_address_view.dart';
import 'package:unshelf_buyer/views/store_reviews_view.dart';

class StoreView extends ConsumerStatefulWidget {
  const StoreView({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends ConsumerState<StoreView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isFollowing = false;
  int _followerCount = 0;
  bool _followLoading = false;

  // Gradient placeholder colours — brand primary tints, no BuildContext needed.
  static const List<Color> _heroGradient = [
    Color(0xFF3F8E4A),
    Color(0xFF6BAF73),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFollowing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(widget.storeId)
        .get();
    if (mounted) {
      setState(() => _isFollowing = doc.exists);
    }
  }

  Future<void> _toggleFollow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _followLoading = true);

    final followRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(widget.storeId);
    final storeRef = _firestore.collection('stores').doc(widget.storeId);

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _followerCount += wasFollowing ? -1 : 1;
    });

    try {
      if (!wasFollowing) {
        await followRef.set({'added_at': FieldValue.serverTimestamp()});
      } else {
        await followRef.delete();
      }
      await storeRef.update({'follower_count': _followerCount});
    } catch (_) {
      // Revert optimistic update
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followerCount += wasFollowing ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update follow. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final storeState = ref.watch(storeViewModelProvider(widget.storeId));

    return Scaffold(
      body: storeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeState.errorMessage != null
              ? _buildError(storeState.errorMessage!)
              : storeState.storeDetails == null
                  ? _buildNoData()
                  : _buildContent(cs, tt, storeState),
    );
  }

  Widget _buildError(String message) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          headline: 'Could not load store',
          body: message,
          ctaLabel: 'Try again',
          onCta: () =>
              ref.refresh(storeViewModelProvider(widget.storeId)),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: EmptyStateView(
          icon: Icons.store_outlined,
          headline: 'Store not found',
          body: 'This store may have been removed.',
        ),
      ),
    );
  }

  Widget _buildContent(
      ColorScheme cs, TextTheme tt, StoreState storeState) {
    final store = storeState.storeDetails!;
    // Sync follower count from the live state
    if (!_followLoading) {
      _followerCount = store.storeFollowers ?? 0;
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // ── Hero SliverAppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              // Follow button
              _followLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _isFollowing
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFollowing
                            ? cs.tertiary
                            : cs.onSurface.withValues(alpha: 0.8),
                      ),
                      tooltip: _isFollowing ? 'Unfollow' : 'Follow',
                      onPressed: _toggleFollow,
                    ),
              // Chat button
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                tooltip: 'Chat',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatView(
                      receiverName: store.storeName,
                      receiverUserID: widget.storeId,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 56),
              title: Text(
                store.storeName,
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  shadows: [
                    const Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or gradient placeholder
                  (store.storeImageUrl != null &&
                          store.storeImageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: store.storeImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _gradientPlaceholder(),
                          errorWidget: (_, __, ___) => _gradientPlaceholder(),
                        )
                      : _gradientPlaceholder(),
                  // Bottom scrim for text legibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                        ],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Info row ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating + followers
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: cs.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        (store.storeRating ?? 0).toStringAsFixed(1),
                        style: tt.labelLarge,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people_outline,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '$_followerCount followers',
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons row
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreAddressView(
                              latitude: store.storeLatitude,
                              longitude: store.storeLongitude,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.place_outlined, size: 18),
                        label: const Text('Location'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StoreReviewsView(storeId: widget.storeId),
                          ),
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Reviews'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Tab bar ───────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Listings'),
                  Tab(text: 'Bundle Deals'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListingsTab(storeId: widget.storeId),
          _BundlesTab(storeId: widget.storeId),
        ],
      ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listings tab
// ---------------------------------------------------------------------------

class _ListingsTab extends StatefulWidget {
  const _ListingsTab({required this.storeId});
  final String storeId;

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<_ListingEntry>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _fetchListings();
  }

  Future<List<_ListingEntry>> _fetchListings() async {
    // Listed batches for this store's products
    final batchesSnap = await _firestore
        .collection('batches')
        .where('isListed', isEqualTo: true)
        .get();

    final Map<String, double> minPrices = {};
    final Set<String> listedIds = {};
    for (final doc in batchesSnap.docs) {
      final data = doc.data();
      final pid = data['productId'] as String?;
      final price = (data['price'] as num?)?.toDouble();
      if (pid == null || price == null) continue;
      listedIds.add(pid);
      if (!minPrices.containsKey(pid) || price < minPrices[pid]!) {
        minPrices[pid] = price;
      }
    }

    if (listedIds.isEmpty) return [];

    final productsSnap = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: listedIds.toList())
        .where('sellerId', isEqualTo: widget.storeId)
        .get();

    return productsSnap.docs.map((doc) {
      final data = doc.data();
      DateTime expiryDate;
      final raw = data['expiryDate'];
      if (raw is Timestamp) {
        expiryDate = raw.toDate();
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 99));
      }

      return _ListingEntry(
        productId: doc.id,
        name: data['name'] as String? ?? '',
        price: minPrices[doc.id] ?? (data['price'] as num?)?.toDouble() ?? 0,
        discount: (data['discount'] as num?)?.toInt() ?? 0,
        expiryDate: expiryDate,
        mainImageUrl: data['mainImageUrl'] as String?,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<_ListingEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: EmptyStateView(
              icon: Icons.error_outline,
              headline: 'Could not load listings',
              body: 'Try again later.',
              ctaLabel: 'Retry',
              onCta: () => setState(() => _future = _fetchListings()),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              headline: 'No listings yet',
              body: 'This store has no active listings right now.',
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return ProductCard.compact(
              productId: p.productId,
              name: p.name,
              price: p.price,
              discount: p.discount,
              expiryDate: p.expiryDate,
              mainImageUrl: p.mainImageUrl,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bundles tab
// ---------------------------------------------------------------------------

class _BundlesTab extends StatefulWidget {
  const _BundlesTab({required this.storeId});
  final String storeId;

  @override
  State<_BundlesTab> createState() => _BundlesTabState();
}

class _BundlesTabState extends State<_BundlesTab>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<QueryDocumentSnapshot>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<QueryDocumentSnapshot>> _fetch() async {
    final snap = await _firestore
        .collection('bundles')
        .where('sellerId', isEqualTo: widget.storeId)
        .get();
    return snap.docs;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              headline: 'No bundle deals',
              body: 'This store has no bundle deals at the moment.',
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final bundleId = docs[index].id;
            final imageUrl = data['mainImageUrl'] as String?;
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final name = data['name'] as String? ?? '';

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BundleView(bundleId: bundleId)),
              ),
              child: Container(
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
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    color: cs.outline.withValues(alpha: 0.12)),
                                errorWidget: (_, __, ___) => Container(
                                    color: cs.outline.withValues(alpha: 0.12)),
                              )
                            : Container(
                                color: cs.outline.withValues(alpha: 0.12)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: tt.labelLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            'PHP ${price.toStringAsFixed(2)}',
                            style: tt.labelLarge?.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: SliverPersistentHeaderDelegate for the TabBar
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Internal data types
// ---------------------------------------------------------------------------

class _ListingEntry {
  const _ListingEntry({
    required this.productId,
    required this.name,
    required this.price,
    required this.discount,
    required this.expiryDate,
    this.mainImageUrl,
  });

  final String productId;
  final String name;
  final double price;
  final int discount;
  final DateTime expiryDate;
  final String? mainImageUrl;
}
