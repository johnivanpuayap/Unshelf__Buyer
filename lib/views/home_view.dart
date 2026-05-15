import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/components/category_row_widget.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/product_card.dart';
import 'package:unshelf_buyer/components/section_header.dart';
import 'package:unshelf_buyer/components/store_card.dart';
import 'package:unshelf_buyer/viewmodels/home_viewmodel.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/notifications_view.dart';
import 'package:unshelf_buyer/views/search_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;
    final firstName = _extractFirstName(user?.displayName);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName != null
                                ? 'Hi, $firstName!'
                                : 'Welcome',
                            style: tt.titleMedium,
                          ),
                          Text(
                            'What are you looking for today?',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notifications icon
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsView()),
                      ),
                      icon: Icon(
                        Icons.notifications_none_outlined,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    // Basket icon
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BasketView()),
                      ),
                      icon: Icon(
                        Icons.shopping_basket_outlined,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search affordance ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => SearchView(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  ),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(25),
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
                        const SizedBox(width: 16),
                        Icon(
                          Icons.search,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search products, stores…',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Hero section ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover near-expiry\nfood in Cebu',
                      style: tt.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Eat well. Waste less.',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: CategoryIconsRow(),
              ),
            ),

            // ── Nearby stores ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Nearby stores'),
                    const SizedBox(height: 8),
                    _NearbyStoresRow(ref: ref),
                  ],
                ),
              ),
            ),

            // ── Expiring soon ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: SectionHeader(title: 'Expiring soon'),
              ),
            ),

            _ExpiringProductsSliver(ref: ref),

            // ── Bottom padding ────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  String? _extractFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return null;
    return displayName.split(' ').first;
  }
}

// ---------------------------------------------------------------------------
// Nearby stores horizontal scroll
// ---------------------------------------------------------------------------

class _NearbyStoresRow extends StatelessWidget {
  const _NearbyStoresRow({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(homeViewModelProvider.notifier);

    return StreamBuilder<QuerySnapshot>(
      stream: vm.getStores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateView(
              icon: Icons.store_outlined,
              headline: 'Could not load stores',
              body: 'Check your connection and try again.',
              ctaLabel: 'Try again',
              onCta: () {},
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: EmptyStateView(
              icon: Icons.store_outlined,
              headline: 'No stores nearby',
              body:
                  'Stores will appear here as they join Unshelf in your area.',
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Expiring-soon product list (sliver)
// ---------------------------------------------------------------------------

class _ExpiringProductsSliver extends StatelessWidget {
  const _ExpiringProductsSliver({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(homeViewModelProvider.notifier);

    return StreamBuilder<QuerySnapshot>(
      stream: vm.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              headline: 'Could not load products',
              body: 'Check your connection and try again.',
              ctaLabel: 'Try again',
              onCta: () {},
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              headline: 'Nothing expiring soon',
              body:
                  'Products with approaching expiry dates will appear here.',
            ),
          );
        }

        // Sort by expiryDate ascending so soonest-to-expire are first
        final sorted = List<DocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aExpiry =
                (aData['expiryDate'] as Timestamp?)?.toDate() ?? DateTime(9999);
            final bExpiry =
                (bData['expiryDate'] as Timestamp?)?.toDate() ?? DateTime(9999);
            return aExpiry.compareTo(bExpiry);
          });

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data = sorted[index].data() as Map<String, dynamic>;
              final productId = sorted[index].id;

              final expiryDate =
                  (data['expiryDate'] as Timestamp?)?.toDate() ??
                      DateTime.now().add(const Duration(days: 7));

              return ProductCard(
                productId: productId,
                name: data['name'] as String? ?? '',
                price: (data['price'] as num?)?.toDouble() ?? 0,
                discount: (data['discount'] as num?)?.toInt() ?? 0,
                expiryDate: expiryDate,
                mainImageUrl: data['mainImageUrl'] as String?,
                storeName: data['storeName'] as String?,
              );
            },
            childCount: sorted.length,
          ),
        );
      },
    );
  }
}
