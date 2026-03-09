import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_model.dart';
import '../../providers/bookmarks_provider.dart';
import '../../theme/app_theme.dart';
import '../reviews/reviews_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksProvider>();
    final isBookmarked = bookmarks.isBookmarked(service.id);
    final position = LatLng(service.latitude, service.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : AppColors.muted,
            ),
            onPressed: () => bookmarks.toggle(service.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Embedded Google Map ───────────────────────────────────
            SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('service'),
                    position: position,
                    infoWindow: InfoWindow(title: service.name),
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),

            // ── Info Card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(Icons.star,
                                  size: 14,
                                  color: i < service.rating.round()
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${service.rating.toStringAsFixed(1)} · ${service.reviewCount} reviews',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(service.category,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text(service.description,
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.5)),
                        const Divider(color: AppColors.border, height: 24),
                        _InfoRow(icon: Icons.location_on, text: service.address),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.phone, text: service.phone),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ReviewsScreen(service: service)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${service.rating.toStringAsFixed(1)} · ${service.reviewCount} reviews',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                              const Spacer(),
                              const Text('View all',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsScreen(
                            service: service, openRateDialog: true),
                      ),
                    ),
                    child: const Text('Rate this service'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${service.latitude},${service.longitude}',
                       );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.directions,
                        color: AppColors.primary),
                    label: const Text('Get directions',
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13))),
      ],
    );
  }
}
