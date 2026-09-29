import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// หน้าจัดการรีวิว (แอดมิน) — ดูรีวิวทั้งหมด + ลบรีวิวที่ไม่เหมาะสม
class ReviewsModerationScreen extends StatefulWidget {
  const ReviewsModerationScreen({super.key});

  @override
  State<ReviewsModerationScreen> createState() => _ReviewsModerationScreenState();
}

class _ReviewsModerationScreenState extends State<ReviewsModerationScreen> {
  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = appState.fetchAllReviews();
  }

  void _reload() => setState(() => _future = appState.fetchAllReviews());

  String _shopName(String shopId) {
    for (final s in appState.shops) {
      if (s.id == shopId) return s.name;
    }
    return 'ร้าน (ไม่พบ)';
  }

  Future<void> _delete(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรีวิว'),
        content: Text('ลบรีวิวของ "${r.authorName}" ต่อร้าน "${_shopName(r.shopId)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await appState.deleteReview(r.id, r.shopId);
    if (mounted) showSnack(context, 'ลบรีวิวแล้ว');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการรีวิว')),
      body: FutureBuilder<List<Review>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snap.data ?? [];
          if (reviews.isEmpty) {
            return Center(
              child: Text('ยังไม่มีรีวิวในระบบ', style: TextStyle(color: AppColors.muted)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('รีวิวทั้งหมด ${reviews.length} รายการ',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted, fontSize: 12.5)),
                  );
                }
                return _card(reviews[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _card(Review r) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconChip(Icons.storefront_rounded, color: AppColors.primary, bg: AppColors.leafSoft, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_shopName(r.shopId),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      overflow: TextOverflow.ellipsis),
                  Text('โดย ${r.authorName.isEmpty ? "ผู้ใช้" : r.authorName}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _delete(r),
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.bad),
            ),
          ]),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
                5,
                (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 15, color: AppColors.accent)),
          ),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
