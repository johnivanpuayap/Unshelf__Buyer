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
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin<MapPage> {
  @override
  bool get wantKeepAlive => true;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng? _currentPosition;
  LatLng basePosition = const LatLng(10.30943566786076, 123.88635816441766);
  bool _isLoading = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<Set<Marker>> _getMarkersWithinRadius(LatLng center, double radius) async {
    final Set<Marker> markers = {};

    try {
      final QuerySnapshot querySnapshot = await _firestore.collection('stores').get();

      for (final QueryDocumentSnapshot doc in querySnapshot.docs) {
        final latitude = (doc.data() as dynamic)['latitude'];
        final longitude = (doc.data() as dynamic)['longitude'];

        if (latitude == 0 || longitude == 0) {
          continue;
        }

        var distanceInMeters = Geolocator.distanceBetween(
          latitude,
          longitude,
          center.latitude,
          center.longitude,
        );

        if (distanceInMeters <= 5000) {
          Marker marker = Marker(
            point: LatLng(latitude, longitude),
            width: 5000,
            height: 5000,
            rotate: true,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreView(storeId: doc.id),
                  ),
                );
              },
              child: const Icon(
                color: Colors.lightGreen,
                Icons.pin_drop_rounded,
                size: 50,
              ),
            ),
          );

          markers.add(marker);
        }
      }
    } catch (e) {
      print('Error fetching markers: $e');
    }
    return markers;
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng location = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = location;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _locationError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_locationError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Location permission denied or error getting location.',
            style: tt.bodyMedium?.copyWith(color: cs.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Near Me",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: cs.secondary, height: 4.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Set<Marker>>(
              future: _getMarkersWithinRadius(_currentPosition!, 500),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading map data.', style: tt.bodyMedium?.copyWith(color: cs.error)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No sellers found within the radius.',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  );
                } else {
                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentPosition!,
                      initialZoom: 20,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'ph.unshelf.buyer',
                      ),
                      CurrentLocationLayer(),
                      MarkerLayer(
                        markers: snapshot.data!.toList(),
                      ),
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
                }
              },
            ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
