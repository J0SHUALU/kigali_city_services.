import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_model.dart';
import '../../models/review_model.dart';
import '../../providers/services_provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  final ServiceModel service;
  final bool openRateDialog;
  const ReviewsScreen({super.key, required this.service, this.openRateDialog = false});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openRateDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRateDialog(context));
    }
  }

  void _showRateDialog(BuildContext context) {
    double selectedRating = 0;
    final commentCtrl = TextEditingController();
    final user = context.read<ap.AuthProvider>().user;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rate ${widget.service.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setModalState(() => selectedRating = i + 1.0),
                  child: Icon(Icons.star, size: 40, color: i < selectedRating ? AppColors.primary : AppColors.border),
                )),
              ),
              const SizedBox(height: 16),
              TextField(controller: commentCtrl, decoration: const InputDecoration(hintText: 'Write a comment (optional)'), maxLines: 3),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: selectedRating == 0 ? null : () async {
                  final review = ReviewModel(
                    id: '',
                    serviceId: widget.service.id,
                    userId: user?.uid ?? '',
                    author: user?.displayName ?? 'Anonymous',
                    rating: selectedRating,
                    comment: commentCtrl.text,
                    timestamp: DateTime.now(),
                  );
                  final navigator = Navigator.of(context);
                  await context.read<ServicesProvider>().addReview(review);
                  navigator.pop();
                },
                child: const Text('Submit Rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ServicesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () => _showRateDialog(context),
        icon: const Icon(Icons.star),
        label: const Text('Rate'),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: provider.getReviewsStream(widget.service.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reviews: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final reviews = snapshot.data ?? [];
          final avg = reviews.isEmpty ? 0.0 : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AVERAGE RATING', style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(avg.toStringAsFixed(1), style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800)),
                    Row(children: [
                      ...List.generate(5, (i) => Icon(Icons.star, size: 18, color: i < avg.round() ? AppColors.primary : AppColors.border)),
                      const SizedBox(width: 8),
                      Text('${reviews.length} reviews', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              ...reviews.map((r) => _ReviewCard(review: r)),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: Text(review.author.isNotEmpty ? review.author[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(review.author, style: const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_timeAgo(review.timestamp), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ]),
              ]),
              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 13, color: i < review.rating.round() ? AppColors.primary : AppColors.border))),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${review.comment}"', style: const TextStyle(color: AppColors.muted, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
