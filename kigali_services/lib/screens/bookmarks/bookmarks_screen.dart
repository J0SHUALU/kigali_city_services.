import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/services_provider.dart';
import '../../theme/app_theme.dart';
import '../detail/service_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksProvider>();
    final allServices = context.watch<ServicesProvider>().services;
    final saved = allServices.where((s) => bookmarks.isBookmarked(s.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: saved.isEmpty
          ? const Center(child: Text('No bookmarks yet.', style: TextStyle(color: AppColors.muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: saved.length,
              itemBuilder: (_, i) {
                final s = saved[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    title: Text(s.name, style: const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600)),
                    subtitle: Text(s.category, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark, color: AppColors.primary),
                      onPressed: () => bookmarks.toggle(s.id),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s))),
                  ),
                );
              },
            ),
    );
  }
}
