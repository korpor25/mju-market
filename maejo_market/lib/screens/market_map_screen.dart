import 'package:flutter/material.dart';
import '../models/stall.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/market_map.dart';

/// หน้าแผนที่ตลาดแบบเต็มจอ — เปิดจากหน้าร้านเพื่อไฮไลต์แผงของร้านนั้น
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
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          AppCard(
            child: MarketMap(
              stalls: appState.stalls,
              selectedId: _sel?.id,
              onTap: (s) => setState(() => _sel = s),
            ),
          ),
          if (_sel != null) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Row(children: [
                IconChip(Icons.storefront_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('แผง ${_sel!.id}${_sel!.shopName != null ? " · ${_sel!.shopName}" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                          _sel!.isEmpty
                              ? 'แผงว่าง · ${_sel!.positionLabel}'
                              : '${_sel!.categoryLabel} · ${_sel!.positionLabel}',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                StatusPill(
                  _sel!.isEmpty ? 'ว่าง' : (_sel!.status == 'due' ? 'ค้างชำระ' : (_sel!.status == 'closed' ? 'ปิดปรับปรุง' : 'เปิดขาย')),
                  tone: _sel!.isEmpty ? 'muted' : (_sel!.status == 'due' ? 'warn' : (_sel!.status == 'closed' ? 'bad' : 'ok')),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
