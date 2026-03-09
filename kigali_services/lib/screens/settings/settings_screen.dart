import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/bookmarks_provider.dart';
import '../../theme/app_theme.dart';
import '../bookmarks/bookmarks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationNotifications = true;
  bool _newServicesAlert = false;
  bool _reviewReplies = true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ap.AuthProvider>().user;
    final bookmarks = context.watch<BookmarksProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text((user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'User', style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _StatCard(label: 'Bookmarks', value: bookmarks.bookmarks.length.toString()),
            const SizedBox(width: 10),
            const _StatCard(label: 'City', value: 'Kigali'),
          ]),
          const SizedBox(height: 24),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.bookmark, color: AppColors.primary),
            title: const Text('My Bookmarks', style: TextStyle(color: AppColors.foreground)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          const SizedBox(height: 24),
          const Text('NOTIFICATIONS', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _ToggleTile(icon: Icons.location_on, label: 'Location-based alerts', value: _locationNotifications, onChanged: (v) => setState(() => _locationNotifications = v)),
          _ToggleTile(icon: Icons.add_circle_outline, label: 'New services', value: _newServicesAlert, onChanged: (v) => setState(() => _newServicesAlert = v)),
          _ToggleTile(icon: Icons.star, label: 'Review replies', value: _reviewReplies, onChanged: (v) => setState(() => _reviewReplies = v)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async => await context.read<ap.AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(color: AppColors.foreground, fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
