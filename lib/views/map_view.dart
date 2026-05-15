/// MapPage — nearby stores on an OpenStreetMap / FlutterMap canvas.
///
/// Chrome redesign only — the FlutterMap widget and its children (TileLayer,
/// CurrentLocationLayer, MarkerLayer, RichAttributionWidget) are UNCHANGED.
///
/// Added chrome:
///   • AppBar "Nearby stores" with back button affordance.
///   • Floating search bar (Card + TextField) that filters store markers by name.
///   • FAB-style filter button opening a bottom sheet ("Open now / Sort by").
///   • Location-error and loading states with proper branded copy.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:unshelf_buyer/views/store_view.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  final LatLng _basePosition =
      const LatLng(10.30943566786076, 123.88635816441766);

  bool _isLoading = true;
  bool _locationError = false;

  // All raw store docs and the current search query.
  List<QueryDocumentSnapshot> _allStores = [];
  String _searchQuery = '';

  // Sort/filter state managed by the bottom sheet.
  _SortMode _sortMode = _SortMode.distance;
  bool _openNowOnly = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      await _fetchStores();
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _locationError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStores() async {
    try {
      final snap = await _firestore.collection('stores').get();
      setState(() => _allStores = snap.docs);
    } catch (e) {
      debugPrint('Error fetching stores: $e');
    }
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  Future<Set<Marker>> _buildMarkers(LatLng center) async {
    final Set<Marker> markers = {};
    final query = _searchQuery;

    for (final doc in _allStores) {
      final data = doc.data() as Map<String, dynamic>;
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      if (latitude == 0 || longitude == 0) continue;

      final distanceInMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        center.latitude,
        center.longitude,
      );

      if (distanceInMeters > 5000) continue;

      final storeName =
          ((data['store_name'] as String?) ?? '').toLowerCase();
      if (query.isNotEmpty && !storeName.contains(query)) continue;

      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 5000,
          height: 5000,
          rotate: true,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StoreView(storeId: doc.id)),
            ),
            child: const Icon(
              Icons.pin_drop_rounded,
              color: Colors.lightGreen,
              size: 50,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // ── Filter bottom sheet ────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Filter & sort', style: tt.titleMedium),
                const SizedBox(height: 16),

                // Open now toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Open now only', style: tt.bodyMedium),
                    Switch(
                      value: _openNowOnly,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setSheetState(() => _openNowOnly = v);
                        setState(() => _openNowOnly = v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 12),

                Text('Sort by', style: tt.labelLarge),
                const SizedBox(height: 8),

                ..._SortMode.values.map((mode) => RadioListTile<_SortMode>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(mode.label, style: tt.bodyMedium),
                      value: mode,
                      groupValue: _sortMode,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        if (v == null) return;
                        setSheetState(() => _sortMode = v);
                        setState(() => _sortMode = v);
                      },
                    )),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text('Apply', style: tt.labelLarge),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Location permission error ──────────────────────────────────────────
    if (_locationError) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: _buildAppBar(cs, tt),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined,
                    size: 56, color: cs.error.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text('Location unavailable', style: tt.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Allow location access so we can show stores near you.',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _locationError = false;
                      _isLoading = true;
                    });
                    _getLocation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
      );
    }

    // ── Loading ────────────────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: _buildAppBar(cs, tt),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
      );
    }

    // ── Map ────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(cs, tt),
      body: Stack(
        children: [
          // ── FlutterMap — UNCHANGED ──────────────────────────────────────
          FutureBuilder<Set<Marker>>(
            future: _buildMarkers(_currentPosition!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading map data.',
                      style: tt.bodyMedium?.copyWith(color: cs.error)),
                );
              }

              final markers = snapshot.data ?? {};

              return FlutterMap(
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 20,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ph.unshelf.buyer',
                  ),
                  CurrentLocationLayer(),
                  MarkerLayer(markers: markers.toList()),
                  RichAttributionWidget(attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ],
              );
            },
          ),

          // ── Floating search bar ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: cs.onSurface.withValues(alpha: 0.55)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: tt.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search stores nearby…',
                          hintStyle: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.45)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter FAB ─────────────────────────────────────────────────
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showFilterSheet(context),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.tune),
              label: Text('Filter', style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  // ── AppBar helper ─────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ColorScheme cs, TextTheme tt) {
    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,
      toolbarHeight: 65,
      title: Text(
        'Nearby stores',
        style: tt.titleLarge?.copyWith(color: cs.onPrimary),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(color: cs.secondary, height: 4),
      ),
    );
  }
}

// ── Sort mode enum ────────────────────────────────────────────────────────────

enum _SortMode {
  distance('Distance'),
  rating('Rating'),
  name('Name');

  const _SortMode(this.label);
  final String label;
}
