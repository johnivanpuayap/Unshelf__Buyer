/// OrderTrackingView — real-time order tracking with status timeline + map.
///
/// Layout:
///   • AppBar: back + "Track order #{id}"
///   • Scrollable body:
///     - OrderStatusTimeline at top
///     - FlutterMap (UNCHANGED) showing store + user location
///   • Pinned bottom card: current status + ETA hint + contact CTA
///
/// FlutterMap widget is kept as-is; only surrounding chrome is new.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:unshelf_buyer/components/order_status_timeline.dart';

class OrderTrackingView extends StatefulWidget {
  /// Optional map center for the store location. Defaults to Cebu City centre.
  final LatLng? storeLocation;

  /// Short display order ID (e.g. "20240501-001").
  final String? orderId;

  /// Current status string from Firestore (e.g. "Pending", "Ready").
  final String? status;

  const OrderTrackingView({
    super.key,
    this.storeLocation,
    this.orderId,
    this.status,
  });

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  late final MapController _mapController;

  static const _cebucity = LatLng(10.3157, 123.8854);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  OrderStage get _currentStage {
    switch (widget.status) {
      case 'Confirmed':
        return OrderStage.confirmed;
      case 'Preparing':
        return OrderStage.preparing;
      case 'Ready':
        return OrderStage.ready;
      case 'Completed':
        return OrderStage.completed;
      default:
        return OrderStage.placed;
    }
  }

  String get _etaLabel {
    switch (widget.status) {
      case 'Pending':
        return 'Waiting for store confirmation';
      case 'Confirmed':
        return 'Store confirmed — preparing soon';
      case 'Preparing':
        return 'Your order is being prepared';
      case 'Ready':
        return 'Ready for pickup now';
      case 'Completed':
        return 'Picked up successfully';
      default:
        return 'Checking status…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final storePin = widget.storeLocation ?? _cebucity;
    final displayId = widget.orderId ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          displayId.isEmpty ? 'Track order' : 'Track order #$displayId',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Status timeline (scrollable section above map) ─────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderStatusTimeline(
                  currentStage: _currentStage,
                ),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
              ],
            ),
          ),

          // ── FlutterMap — DO NOT TOUCH ──────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: storePin,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ph.unshelf.buyer',
                ),
                CurrentLocationLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: storePin,
                      rotate: true,
                      child: Icon(
                        Icons.store_outlined,
                        color: cs.primary,
                        size: 36,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black38),
                        ],
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      textStyle: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── END FlutterMap — DO NOT TOUCH ──────────────────────────────
        ],
      ),

      // ── Pinned status card ─────────────────────────────────────────────
      bottomSheet: _StatusCard(
        status: widget.status ?? '',
        etaLabel: _etaLabel,
        cs: cs,
        tt: tt,
      ),
    );
  }
}

// ─── Pinned status card ───────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.etaLabel,
    required this.cs,
    required this.tt,
  });

  final String status;
  final String etaLabel;
  final ColorScheme cs;
  final TextTheme tt;

  Color get _statusColor {
    switch (status) {
      case 'Pending':
        return cs.secondaryContainer;
      case 'Confirmed':
      case 'Preparing':
      case 'Ready':
        return cs.primaryContainer;
      case 'Completed':
        return cs.surfaceContainerHighest;
      case 'Cancelled':
        return cs.errorContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Color get _statusTextColor {
    switch (status) {
      case 'Pending':
        return cs.onSecondaryContainer;
      case 'Confirmed':
      case 'Preparing':
      case 'Ready':
        return cs.onPrimaryContainer;
      case 'Completed':
        return cs.onSurface;
      case 'Cancelled':
        return cs.onErrorContainer;
      default:
        return cs.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.isEmpty ? '—' : status,
                  style: tt.labelMedium?.copyWith(
                    color: _statusTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  etaLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Contact store CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contact store'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: cs.primary),
                foregroundColor: cs.primary,
              ),
              onPressed: () {
                // Navigation to chat implemented in Group H
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat coming soon.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
