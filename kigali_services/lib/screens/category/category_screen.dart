import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/services_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/service_model.dart';
import '../detail/service_detail_screen.dart';
import '../listing/add_edit_listing_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read listings from Provider state — no StreamBuilder, no direct Firestore
    // queries in the UI (satisfies Requirement 5).
    final provider = context.watch<ServicesProvider>();
    final listings = provider.myListings;
    final loadingState = provider.myListingsState;

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: loadingState == LoadingState.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : loadingState == LoadingState.error
              ? const Center(
                  child: Text(
                    'Failed to load listings. Check your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                )
              : listings.isEmpty
              ? const Center(
                  child: Text(
                    'You have not added any listings yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (_, i) => _MyListingCard(service: listings[i]),
                ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final ServiceModel service;
  const _MyListingCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.read<ServicesProvider>();
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(service.name,
            style: const TextStyle(
                color: AppColors.foreground, fontWeight: FontWeight.w600)),
        subtitle: Text(service.category,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: AppColors.muted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddEditListingScreen(service: service)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () =>
                  _confirmDelete(context, servicesProvider),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: service)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServicesProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete listing?',
            style: TextStyle(color: AppColors.foreground)),
        content: Text('This will permanently delete "${service.name}".',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteService(service.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
