// // views/edit_store_location_view.dart
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:unshelf_buyer/viewmodels/address_viewmodel.dart';

// class EditStoreLocationView extends StatelessWidget {
//   final StoreModel storeDetails;

//   EditStoreLocationView({required this.storeDetails});

//   @override
//   Widget build(BuildContext context) {
//     final viewModel = Provider.of<AddressViewModel>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Choose a Location'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: () async {
//               try {
//                 await viewModel.saveLocation();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Location saved successfully!')),
//                 );
//                 Navigator.pop(context, true);
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Failed to save location: $e')),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: storeDetails.storeLatitude != null && storeDetails.storeLongitude != null
//               ? LatLng(
//                   storeDetails.storeLatitude!,
//                   storeDetails.storeLongitude!,
//                 )
//               : LatLng(1.3521, 103.8198),
//           zoom: 15,
//         ),
//         onMapCreated: viewModel.setMapController,
//         onTap: (LatLng location) {
//           viewModel.updateLocation(location);
//         },
//         markers: {
//           Marker(
//             markerId: MarkerId('chosen_location'),
//             position: LatLng(
//               storeDetails.storeLatitude ?? 1.3521,
//               storeDetails.storeLongitude ?? 103.8198,
//             ),
//             draggable: true,
//             onDragEnd: (LatLng newPosition) {
//               viewModel.updateLocation(newPosition);
//             },
//           ),
//         },
//       ),
//     );
//   }
// }
