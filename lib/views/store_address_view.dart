import 'package:unshelf_buyer/utils/colors.dart';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          'Store Location',
          style: TextStyle(color: Colors.white, fontSize: 25.0),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            latitude!,
            longitude!,
          ), // Center the map over London
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latitude!, longitude!),
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
