import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class StoreAddressView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? storeName;
  final String? storeAddress;

  const StoreAddressView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.storeName,
    this.storeAddress,
  });

  void _openDirections(BuildContext context) {
    // url_launcher not yet added; show coordinates for now.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Navigate to: $latitude, $longitude\n(Open in maps — coming soon)'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final title = storeName ?? 'Store location';

    return Scaffold(
      // ── AppBar chrome ──────────────────────────────────────────────────
      appBar: AppBar(
        title: Text(title, style: tt.titleLarge),
      ),
      // ── Body: full-screen map ──────────────────────────────────────────
      body: Stack(
        children: [
          // FlutterMap — UNTOUCHED
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.unshelf.buyer',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    rotate: true,
                    child: const Icon(
                      color: Colors.lightGreen,
                      Icons.pin_drop_rounded,
                      size: 50,
                    ),
                  ),
                ],
              ),
              CurrentLocationLayer(),
            ],
          ),

          // ── Bottom info card overlay ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomInfoCard(
              cs: cs,
              tt: tt,
              storeName: title,
              storeAddress: storeAddress,
              onDirections: () => _openDirections(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({
    required this.cs,
    required this.tt,
    required this.storeName,
    this.storeAddress,
    required this.onDirections,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final String storeName;
  final String? storeAddress;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Store name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.storefront_outlined,
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeName,
                            style: tt.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (storeAddress != null &&
                            storeAddress!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            storeAddress!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Get directions CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 20),
                  label: Text(
                    'Get directions',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: cs.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
