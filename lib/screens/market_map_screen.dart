import 'package:flutter/material.dart';
import '../models/stall.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/market_map.dart';
import '../widgets/stall_info_card.dart';

/// หน้าแผนที่ตลาดแบบเต็มจอ — เปิดจากหน้าร้านเพื่อไฮไลต์แผงของร้านนั้น
/// เป็นทางฝั่งผู้ซื้อ จึงแสดงเฉพาะแผงที่มีร้านอยู่
class MarketMapScreen extends StatefulWidget {
  final String? focusStallId;
  const MarketMapScreen({super.key, this.focusStallId});

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen> {
  Stall? _sel;

  @override
  void initState() {
    super.initState();
    final id = widget.focusStallId;
    if (id != null) {
      for (final s in appState.stalls) {
        if (s.id == id) {
          _sel = s;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ตลาดแม่โจ้')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.focusStallId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Icon(Icons.push_pin_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('ไฮไลต์แผง ${widget.focusStallId} ของร้าน',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          AppCard(
            child: MarketMap(
              stalls: appState.stalls,
              selectedId: _sel?.id,
              hideEmpty: true,
              onTap: (s) => setState(() => _sel = s),
            ),
          ),
          if (_sel != null) ...[
            const SizedBox(height: 14),
            StallInfoCard(stall: _sel!),
          ],
        ],
      ),
    );
  }
}
