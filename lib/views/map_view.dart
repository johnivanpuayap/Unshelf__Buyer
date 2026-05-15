import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';
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

        // Filter out invalid coordinates manually
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
                        builder: (context) => StoreView(
                              storeId: doc.id,
                            )),
                  );
                },
                child: const Icon(
                  color: Colors.lightGreen,
                  Icons.pin_drop_rounded,
                  size: 50,
                ),
              ));

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
    if (_locationError) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Location permission denied or error getting location.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0AB68B),
          elevation: 0,
          toolbarHeight: 65,
          title: const Text(
            "Near Me",
            style: TextStyle(color: Colors.white, fontSize: 25.0),
          ),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: Container(
                color: const Color(0xFF92DE8B),
                height: 6.0,
              )),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FutureBuilder<Set<Marker>>(
                future: _getMarkersWithinRadius(_currentPosition!, 500),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading map data.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No sellers found within the radius.'));
                  } else {
                    return FlutterMap(
                      options: MapOptions(
                        initialCenter: _currentPosition!, // Center the map over user's current position
                        initialZoom: 20,
                      ),
                      children: [
                        TileLayer(
                          // Display map tiles from any source
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                          userAgentPackageName: 'com.example.app',
                          // And many more recommended properties!
                        ),
                        CurrentLocationLayer(),
                        MarkerLayer(
                          markers: snapshot.data!.toList(),
                        )
                      ],
                    );
                  }
                },
              ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1));
  }
}
