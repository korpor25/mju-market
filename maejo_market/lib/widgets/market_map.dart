import 'package:flutter/material.dart';
import '../models/stall.dart';
import '../theme/app_colors.dart';

/// แผนผังตลาดแบบดิจิทัล (ใช้ร่วมกันหลายหน้า)
class MarketMap extends StatelessWidget {
  final List<Stall> stalls;
  final String? selectedId;
  final void Function(Stall) onTap;
  const MarketMap({super.key, required this.stalls, this.selectedId, required this.onTap});

  static Color colorOf(String status) {
    switch (status) {
      case 'occupied':
        return AppColors.primary;
      case 'due':
        return AppColors.accent;
      case 'closed':
        return AppColors.bad;
      default:
        return AppColors.surface2; // empty
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = <String, List<Stall>>{};
    for (final s in stalls) {
      zones.putIfAbsent(s.zone, () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 14, runSpacing: 6, children: const [
          _Legend(color: AppColors.primary, label: 'เปิดขาย'),
          _Legend(color: AppColors.surface2, label: 'ว่าง', border: true),
          _Legend(color: AppColors.accent, label: 'ค้างชำระ'),
          _Legend(color: AppColors.bad, label: 'ปิดปรับปรุง'),
        ]),
        const SizedBox(height: 14),
        ...zones.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('โซน ${e.key}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: e.value.map((s) => _StallBox(
                          stall: s,
                          selected: s.id == selectedId,
                          onTap: () => onTap(s),
                        )).toList(),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _StallBox extends StatelessWidget {
  final Stall stall;
  final bool selected;
  final VoidCallback onTap;
  const _StallBox({required this.stall, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = MarketMap.colorOf(stall.status);
    final empty = stall.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 58,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryDark : (empty ? AppColors.border : Colors.transparent),
            width: selected ? 2.5 : 1.4,
          ),
        ),
        child: Text(
          stall.id,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: empty ? AppColors.muted : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;
  const _Legend({required this.color, required this.label, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: border ? Border.all(color: AppColors.border) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
    ]);
  }
}
