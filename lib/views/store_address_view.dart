import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class StoreAddressView extends StatelessWidget {
  final double latitude;
  final double longitude;

  const StoreAddressView({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          'Store Location',
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            latitude,
            longitude,
          ),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
    );
  }
}
