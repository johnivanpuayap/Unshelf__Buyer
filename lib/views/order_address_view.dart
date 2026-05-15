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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final vmState = ref.watch(orderAddressViewModelProvider);
    final vm = ref.read(orderAddressViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          'Choose a Location',
          style: tt.titleMedium?.copyWith(color: cs.onPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: cs.onPrimary),
            onPressed: () async {
              try {
                await vm.saveLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location saved successfully!')),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save location: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: FlutterMap(
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
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ph.unshelf.buyer',
          ),
          const CurrentLocationLayer(),
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
    );
  }
}
