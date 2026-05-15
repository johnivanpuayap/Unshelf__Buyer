// views/order_address_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/viewmodels/order_address_viewmodel.dart';

class EditOrderAddressView extends ConsumerStatefulWidget {
  const EditOrderAddressView({super.key});

  @override
  ConsumerState<EditOrderAddressView> createState() =>
      _EditOrderAddressViewState();
}

class _EditOrderAddressViewState extends ConsumerState<EditOrderAddressView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;

  // ─── Address confirmation ─────────────────────────────────────────────

  Future<void> _confirmAddress() async {
    setState(() => _isSaving = true);
    final vm = ref.read(orderAddressViewModelProvider.notifier);
    try {
      await vm.saveLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery address saved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save address: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final vmState = ref.watch(orderAddressViewModelProvider);
    final vm = ref.read(orderAddressViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          'Choose delivery address',
          style: tt.titleMedium?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
      ),

      // ── Body: map (unchanged) + floating search bar overlay ───────────
      body: Stack(
        children: [
          // ── FlutterMap widget — DO NOT TOUCH ───────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: vmState.chosenLocation,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                vm.updateLocation(point);
              },
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
                    point: vmState.chosenLocation,
                    rotate: true,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  textStyle: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                  ),
                ),
              ]),
            ],
          ),
          // ── END FlutterMap — DO NOT TOUCH ──────────────────────────────

          // ── Floating search bar at top of map ──────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _SearchBar(
              controller: _searchController,
              cs: cs,
              tt: tt,
            ),
          ),
        ],
      ),

      // ── Confirm address CTA ────────────────────────────────────────────
      bottomSheet: _ConfirmSheet(
        chosenLocation: vmState.chosenLocation,
        isSaving: _isSaving,
        onConfirm: _confirmAddress,
        cs: cs,
        tt: tt,
      ),
    );
  }
}

// ─── Floating search bar ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.cs,
    required this.tt,
  });

  final TextEditingController controller;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search for an address…',
          hintStyle:
              tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
          prefixIcon:
              Icon(Icons.search_outlined, color: cs.onSurface.withValues(alpha: 0.5)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close,
                      color: cs.onSurface.withValues(alpha: 0.5), size: 18),
                  onPressed: () => controller.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Confirm address bottom sheet ─────────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.chosenLocation,
    required this.isSaving,
    required this.onConfirm,
    required this.cs,
    required this.tt,
  });

  final LatLng chosenLocation;
  final bool isSaving;
  final VoidCallback onConfirm;
  final ColorScheme cs;
  final TextTheme tt;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Selected coordinates label
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${chosenLocation.latitude.toStringAsFixed(5)}, '
                  '${chosenLocation.longitude.toStringAsFixed(5)}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: cs.primary,
              ),
              onPressed: isSaving ? null : onConfirm,
              child: isSaving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      'Confirm address',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
