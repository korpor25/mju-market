import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/stall.dart';
import '../theme/app_colors.dart';

/// แผนผังบูธ/แผงในตลาดแบบดิจิทัล (ใช้ร่วมกันหลายหน้า)
///
/// จัดวางเป็น "ผังตลาด" จริง: มีจุดทางเข้า–ออก แบ่งเป็นโซน คั่นด้วยทางเดิน
/// บูธว่างเป็นเส้นประ (จองได้) บูธที่มีร้านแสดงไอคอนตามสถานะ
/// วิธีจัดกลุ่มบล็อกในผัง
/// - [zone]     : ตามโซน A/B/C/D (มุมมองผู้ดูแล/ผู้ขาย — เน้นตำแหน่ง)
/// - [category] : ตามหมวดสินค้า (มุมมองผู้บริโภค — เน้นว่าจะไปซื้ออะไร)
enum MapGrouping { zone, category }

class MarketMap extends StatelessWidget {
  final List<Stall> stalls;
  final String? selectedId;
  final void Function(Stall) onTap;

  /// จัดกลุ่มตามอะไร (ค่าเริ่มต้น = โซน)
  final MapGrouping grouping;

  /// แสดงค่าเช่าบนแผงว่าง — ใช้ในหน้าจองแผงของผู้ขาย
  final bool showPrice;

  const MarketMap({
    super.key,
    required this.stalls,
    this.selectedId,
    required this.onTap,
    this.grouping = MapGrouping.zone,
    this.showPrice = false,
  });

  /// ป้ายกลุ่มของแผงที่ไม่ได้กำหนดหมวด — จัดไว้ท้ายผังเสมอ
  static const unknownCategory = 'ไม่ระบุหมวด';

  static IconData iconOfCategory(String c) {
    switch (c) {
      case 'ผัก / ผลไม้':
        return Icons.eco_rounded;
      case 'อาหาร':
        return Icons.ramen_dining_rounded;
      case 'เครื่องดื่ม':
        return Icons.local_cafe_rounded;
      case 'ประมง':
        return Icons.set_meal_rounded;
      case 'ของแห้ง':
        return Icons.rice_bowl_rounded;
      case 'ของใช้':
        return Icons.shopping_basket_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

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
    // จัดกลุ่มตามโซนหรือหมวดสินค้า + นับสถานะรวม
    final byCategory = grouping == MapGrouping.category;
    final groups = <String, List<Stall>>{};
    final counts = <String, int>{'occupied': 0, 'empty': 0, 'due': 0, 'closed': 0};
    for (final s in stalls) {
      groups.putIfAbsent(byCategory ? s.categoryLabel : s.zone, () => []).add(s);
      counts[s.status] = (counts[s.status] ?? 0) + 1;
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == unknownCategory) return 1;
        if (b == unknownCategory) return -1;
        return a.compareTo(b);
      });
    for (final list in groups.values) {
      // เรียงตามโซนก่อนแล้วค่อยเลขแผง เพื่อให้กลุ่มหมวดยังอ่านตำแหน่งได้
      list.sort((a, b) =>
          a.zone == b.zone ? a.number.compareTo(b.number) : a.zone.compareTo(b.zone));
    }

    final blocks = <Widget>[const _Entrance()];
    for (var i = 0; i < groupKeys.length; i++) {
      final k = groupKeys[i];
      blocks.add(SizedBox(height: i == 0 ? 16 : 0));
      blocks.add(_GroupBlock(
        label: k,
        byCategory: byCategory,
        stalls: groups[k]!,
        selectedId: selectedId,
        showPrice: showPrice,
        onTap: onTap,
      ));
      if (i != groupKeys.length - 1) {
        blocks.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: _Walkway(),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // คำอธิบายสี + จำนวน
        Wrap(spacing: 14, runSpacing: 8, children: [
          _Legend(color: AppColors.primary, label: 'เปิดขาย', count: counts['occupied']!),
          _Legend(color: AppColors.surface2, label: 'ว่าง', count: counts['empty']!, border: true),
          _Legend(color: AppColors.accent, label: 'ค้างชำระ', count: counts['due']!),
          _Legend(color: AppColors.bad, label: 'ปิดปรับปรุง', count: counts['closed']!),
        ]),
        const SizedBox(height: 14),
        // กรอบผังตลาด
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks),
        ),
      ],
    );
  }
}

/// แถบทางเข้า–ออกตลาด (ด้านบนของผัง)
class _Entrance extends StatelessWidget {
  const _Entrance();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.leafSoft,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.meeting_room_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('ทางเข้า–ออกตลาด',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ]),
      ),
    );
  }
}

/// บล็อกของหนึ่งกลุ่ม (โซน หรือ หมวดสินค้า): หัวข้อ + จำนวนแผงที่เปิด + บูธ
class _GroupBlock extends StatelessWidget {
  final String label;
  final bool byCategory;
  final List<Stall> stalls;
  final String? selectedId;
  final bool showPrice;
  final void Function(Stall) onTap;
  const _GroupBlock({
    required this.label,
    required this.byCategory,
    required this.stalls,
    required this.selectedId,
    required this.showPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final open = stalls.where((s) => s.status == 'occupied').length;
    // ตอนจัดตามหมวด ต้องบอกด้วยว่าหมวดนี้กระจายอยู่โซนไหนบ้าง
    // ไม่งั้นผู้บริโภคเห็นหมวดแต่ไม่รู้ว่าต้องเดินไปทางไหน
    final zones =
        byCategory ? (stalls.map((s) => s.zone).toSet().toList()..sort()).join(', ') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: byCategory
                ? Icon(MarketMap.iconOfCategory(label), size: 15, color: Colors.white)
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(byCategory ? label : 'โซน $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 13.5)),
                if (zones.isNotEmpty)
                  Text('โซน $zones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text('เปิด $open/${stalls.length}',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stalls
              .map((s) => _StallBox(
                    stall: s,
                    selected: s.id == selectedId,
                    showPrice: showPrice,
                    onTap: () => onTap(s),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// เส้น "ทางเดิน" คั่นระหว่างโซน
class _Walkway extends StatelessWidget {
  const _Walkway();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: CustomPaint(size: const Size(double.infinity, 1), painter: _AisleLinePainter())),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.directions_walk_rounded, size: 13, color: AppColors.faint),
          const SizedBox(width: 3),
          Text('ทางเดิน',
              style: TextStyle(fontSize: 10.5, color: AppColors.faint, fontWeight: FontWeight.w700)),
        ]),
      ),
      Expanded(child: CustomPaint(size: const Size(double.infinity, 1), painter: _AisleLinePainter())),
    ]);
  }
}

/// บูธเดี่ยว
class _StallBox extends StatelessWidget {
  final Stall stall;
  final bool selected;
  final bool showPrice;
  final VoidCallback onTap;
  const _StallBox({
    required this.stall,
    required this.selected,
    required this.showPrice,
    required this.onTap,
  });

  static const _icons = <String, IconData>{
    'occupied': Icons.storefront_rounded,
    'due': Icons.schedule_rounded,
    'closed': Icons.do_not_disturb_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = MarketMap.colorOf(stall.status);
    final empty = stall.isEmpty;
    final ic = empty ? Icons.add_rounded : _icons[stall.status];

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (ic != null)
          Icon(ic,
              size: 15,
              color: empty ? AppColors.faint : Colors.white.withValues(alpha: 0.92)),
        const SizedBox(height: 1),
        Text(
          stall.id,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: empty ? AppColors.muted : Colors.white,
          ),
        ),
        if (showPrice)
          Text(
            '฿${stall.pricePerDay}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
              color: empty ? AppColors.faint : Colors.white.withValues(alpha: 0.85),
            ),
          ),
      ],
    );

    Widget box = Container(
      width: 62,
      height: showPrice ? 66 : 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: empty ? AppColors.surface : c,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryDark : Colors.transparent,
          width: selected ? 2.5 : 0,
        ),
        boxShadow: selected
            ? [BoxShadow(color: c.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      child: content,
    );

    // บูธว่าง (ยังไม่ถูกเลือก) ใช้เส้นประบอกว่า "จองได้"
    if (empty && !selected) {
      box = CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: AppColors.border, radius: 12),
        child: box,
      );
    }

    return InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: box);
  }
}

/// วาดเส้นประรอบสี่เหลี่ยมมน (สำหรับบูธว่าง)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, this.radius = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
        const Offset(0.7, 0.7) & Size(size.width - 1.4, size.height - 1.4),
        Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 5.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// เส้นประแนวนอนของทางเดิน
class _AisleLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2;
    const dash = 5.0, gap = 5.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_AisleLinePainter old) => false;
}

/// คำอธิบายสี + จำนวน
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool border;
  const _Legend({required this.color, required this.label, required this.count, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: border ? Border.all(color: AppColors.border) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text('$label ',
          style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
      Text('$count',
          style: TextStyle(fontSize: 11.5, color: AppColors.text, fontWeight: FontWeight.w800)),
    ]);
  }
}
