// views/edit_store_location_view.dart
import 'package:unshelf_buyer/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditOrderAddressView extends StatelessWidget {
  // final StoreModel storeDetails;
  double latitude = 10.3157;
  double longitude = 123.8854;

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          'Choose a Location',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                // save location logic
                // viewModel.saveLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location saved successfully!')),
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save location: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: latitude != null && longitude != null
              ? LatLng(
                  latitude!,
                  longitude!,
                )
              : const LatLng(10.3521, 103.8198),
          zoom: 15,
        ),
        onMapCreated: setMapController,
        onTap: (LatLng location) {
          latitude = location.latitude;
          longitude = location.longitude;
          ("LOCATION:  $latitude $longitude");
          // update location!
          // viewModel.updateLocation(location);
        },
        markers: {
          Marker(
            markerId: const MarkerId('chosen_location'),
            position: LatLng(
              latitude ?? 10.3092615,
              longitude ?? 123.8863528,
            ),
            draggable: true,
            onDragEnd: (LatLng newPosition) {
              latitude = newPosition.latitude;
              longitude = newPosition.longitude;
              ("POSITION:  $latitude $longitude");
              // viewModel.updateLocation(newPosition);
              // insert update location logic here
            },
          ),
        },
      ),
    );
  }

  setMapController(GoogleMapController controller) {
    _mapController = controller;
  }
}
