import 'package:flutter/material.dart';

import '../services/visit_history.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'shop_detail_screen.dart';

/// ประวัติการเข้าชมร้าน — อ่านจากเครื่อง ไม่ต้องล็อกอิน
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<VisitedShop> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await VisitHistory.load();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ล้างประวัติ'),
        content: const Text('ลบรายการร้านที่เคยเข้าดูทั้งหมดใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: const Text('ล้างประวัติ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await VisitHistory.clear();
    if (!mounted) return;
    setState(() => _items = []);
    showSnack(context, 'ล้างประวัติแล้ว');
  }

  /// เปิดหน้าร้านจากประวัติ — ร้านอาจถูกปิดหรือลบไปแล้วหลังจากที่เคยเข้าดู
  void _open(VisitedShop v) {
    final found = appState.shops.where((s) => s.id == v.id);
    if (found.isEmpty) {
      showSnack(context, 'ร้าน ${v.name} ไม่อยู่ในตลาดแล้ว', bad: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: found.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการเข้าชม'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'ล้างประวัติ',
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    EmptyState(
                      icon: Icons.history_rounded,
                      message: 'ยังไม่มีประวัติการเข้าชม\nร้านที่คุณเปิดดูจะมาอยู่ตรงนี้',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('เก็บไว้ในเครื่องของคุณเท่านั้น ย้อนหลังได้ ${VisitHistory.maxItems} ร้านล่าสุด',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const SizedBox(height: 12),
                    GroupedCard(
                      children: [
                        for (final v in _items)
                          AppListRow(
                            leading: NetImage(
                              url: v.imageUrl,
                              width: 46,
                              height: 46,
                              radius: 12,
                            ),
                            title: v.name.isEmpty ? 'ร้านค้า' : v.name,
                            subtitle: v.whereLabel,
                            note: _timeAgo(v.at),
                            trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                            onTap: () => _open(v),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

String _timeAgo(int millis) {
  if (millis <= 0) return '';
  final diff = DateTime.now().millisecondsSinceEpoch - millis;
  final m = diff ~/ 60000;
  if (m < 1) return 'เมื่อสักครู่';
  if (m < 60) return '$m นาทีที่แล้ว';
  final h = m ~/ 60;
  if (h < 24) return '$h ชั่วโมงที่แล้ว';
  final d = h ~/ 24;
  return '$d วันที่แล้ว';
}
