import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/service_model.dart';
import '../detail/service_detail_screen.dart';
import '../listing/add_edit_listing_screen.dart';

const List<String> kCategories = [
  'Cafés', 'Pharmacies', 'Hospitals', 'Restaurants',
  'Parks', 'Libraries', 'Police', 'Attractions',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicesProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.location_on, color: AppColors.primary),
        ),
        title: const Text('Kigali City'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditListingScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = kCategories[i];
                final active = provider.selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: active,
                  onSelected: (_) => provider.setCategory(cat),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: active ? Colors.black : AppColors.foreground, fontWeight: FontWeight.w500),
                  side: BorderSide(color: active ? AppColors.primary : AppColors.border),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search for a service',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.muted),
                        onPressed: () { _searchCtrl.clear(); provider.setSearchQuery(''); },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.state == LoadingState.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : provider.state == LoadingState.error
                    ? Center(child: Text(provider.errorMessage ?? 'Error', style: const TextStyle(color: AppColors.error)))
                    : provider.services.isEmpty
                        ? const Center(child: Text('No services found.', style: TextStyle(color: AppColors.muted)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: provider.services.length,
                            itemBuilder: (_, i) => _ServiceCard(service: provider.services[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksProvider>();
    final isBookmarked = bookmarks.isBookmarked(service.id);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) => Icon(Icons.star, size: 12,
                          color: i < service.rating.round() ? AppColors.primary : AppColors.border)),
                    ),
                    const SizedBox(height: 4),
                    Text(service.category, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(service.rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const Icon(Icons.star, color: AppColors.primary, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => bookmarks.toggle(service.id),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.primary : AppColors.muted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
