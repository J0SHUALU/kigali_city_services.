import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/services_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/service_model.dart';
import '../detail/service_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ServiceModel? _selected;

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServicesProvider>().services;

    // Default center: Kigali City
    const kigaliCenter = LatLng(-1.9441, 30.0619);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          // ── Full screen Google Map ───────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: kigaliCenter,
              zoom: 13,
            ),
            markers: services.map((s) {
              return Marker(
                markerId: MarkerId(s.id),
                position: LatLng(s.latitude, s.longitude),
                infoWindow: InfoWindow(
                  title: s.name,
                  snippet: s.category,
                ),
                onTap: () => setState(() => _selected = s),
              );
            }).toSet(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // ── Bottom card when a marker is tapped ─────────────────
          if (_selected != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected!.name,
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selected!.category,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.primary, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  _selected!.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceDetailScreen(
                                    service: _selected!),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('View'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selected = null),
                            child: const Text('Close',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
