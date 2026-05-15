/// StoreCard — horizontal card used in the "Nearby stores" section of the
/// home view and any other context that surfaces a single store in a carousel.
///
/// Displays a cover image (or gradient placeholder), store name, rating and
/// follower count.  Tap navigates to [StoreView].
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.storeId,
    required this.storeName,
    this.storeImageUrl,
    this.rating,
    this.followerCount,
  });

  final String storeId;
  final String storeName;
  final String? storeImageUrl;
  final double? rating;
  final int? followerCount;

  // Gradient uses brand primary and a lighter variant; defined here so they
  // match the tokens without needing BuildContext inside a const list.
  static const List<Color> _placeholderGradients = [
    Color(0xFF3F8E4A), // UnshelfTokens.colorLightPrimary
    Color(0xFF6BAF73), // lighter tint of primary
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreView(storeId: storeId)),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
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
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: (storeImageUrl != null && storeImageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: storeImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _gradientPlaceholder(),
                        errorWidget: (_, __, ___) => _gradientPlaceholder(),
                      )
                    : _gradientPlaceholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: tt.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (rating != null) ...[
                        Icon(Icons.star_rounded,
                            size: 14, color: cs.tertiary),
                        const SizedBox(width: 2),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      if (rating != null && followerCount != null)
                        Text(
                          ' · ',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      if (followerCount != null)
                        Text(
                          '$followerCount followers',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _placeholderGradients,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}
