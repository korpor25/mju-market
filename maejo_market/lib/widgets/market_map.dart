import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/market_layout.dart';
import '../models/stall.dart';
import '../theme/app_colors.dart';

/// แผนผังตลาดแม่โจ้ — วาดตามผังจริงที่ตลาดให้มา (ดู [MarketLayout])
///
/// แต่ละแผงอยู่ตำแหน่งเดียวกับของจริง พื้นหลังแยกย่านด้วยสี
/// ตัวแผงใช้สีตามสถานะชุดเดียวทั้งผัง (เปิดขาย/ว่าง/ค้างชำระ/ปิด)
/// และแยก "กดได้" กับ "กดไม่ได้" ให้เห็นทันที
///   กดได้    = พื้นทึบหรือขอบเขียวเข้ม + เงา + ไอคอนนิ้วแตะ
///   กดไม่ได้ = พื้นเทาจาง ไม่มีเงา + ไอคอนกุญแจ
/// ย่อ–ขยายด้วยสองนิ้วได้ เพราะผังจริงมีแผงยาวบาง ๆ หลายแถว
class MarketMap extends StatelessWidget {
  final List<Stall> stalls;
  final String? selectedId;
  final void Function(Stall) onTap;

  /// แสดงค่าเช่าบนแผงว่าง — ใช้ในหน้าจองแผงของผู้ขาย
  final bool showPrice;

  /// แผงไหนกดได้ — ไม่ส่งมา = กดได้ทุกแผงที่มีในระบบ
  /// (หน้าจองแผงของผู้ขายส่ง `isBookable` ให้กดได้เฉพาะแผงว่าง)
  final bool Function(Stall)? canTap;

  const MarketMap({
    super.key,
    required this.stalls,
    this.selectedId,
    required this.onTap,
    this.showPrice = false,
    this.canTap,
  });

  /// สีตามสถานะแผง (ใช้ในหน้าจัดการแผงด้วย)
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

  static String labelOf(String status) {
    switch (status) {
      case 'occupied':
        return 'เปิดขาย';
      case 'due':
        return 'ค้างชำระ';
      case 'closed':
        return 'ปิดปรับปรุง';
      default:
        return 'ว่าง';
    }
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final s in stalls) s.id: s};
    // แผงที่แอดมินสร้างไว้แต่ไม่มีตำแหน่งในผัง — แสดงแยกด้านล่าง จะได้ไม่หายไป
    final offPlan = stalls.where((s) => MarketLayout.slotOf(s.id) == null).toList()
      ..sort((a, b) => a.zone == b.zone ? a.number.compareTo(b.number) : a.zone.compareTo(b.zone));

    final counts = <String, int>{'occupied': 0, 'empty': 0, 'due': 0, 'closed': 0};
    for (final s in stalls) {
      counts[s.status] = (counts[s.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(
          counts: counts,
          lockedHint: canTap == null ? 'แผงที่ยังไม่เปิดให้เช่า' : 'แผงไม่ว่าง / ยังไม่เปิด',
        ),
        const SizedBox(height: 14),

        // ---- ตัวผัง ----
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface2.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(8),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: AspectRatio(
                aspectRatio: kPlanCanvas.width / kPlanCanvas.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: kPlanCanvas.width,
                    height: kPlanCanvas.height,
                    child: _PlanStack(
                      byId: byId,
                      selectedId: selectedId,
                      showPrice: showPrice,
                      canTap: canTap,
                      onTap: onTap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.pinch_rounded, size: 14, color: AppColors.faint),
          const SizedBox(width: 5),
          Expanded(
            child: Text('ซูมด้วยสองนิ้ว หรือกดดูเต็มจอ',
                maxLines: 2, style: TextStyle(fontSize: 11, color: AppColors.faint)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarketMapFullScreen(
                  stalls: stalls,
                  selectedId: selectedId,
                  showPrice: showPrice,
                  canTap: canTap,
                  onTap: onTap,
                ),
              ),
            ),
            icon: const Icon(Icons.open_in_full_rounded, size: 17),
            label: const Text('ดูเต็มจอ'),
          ),
        ]),

        if (offPlan.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('แผงนอกผัง (${offPlan.length})',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in offPlan)
                SizedBox(
                  width: 84,
                  height: 58,
                  child: _StallTile(
                    id: s.id,
                    stall: s,
                    tappable: canTap?.call(s) ?? true,
                    selected: s.id == selectedId,
                    showPrice: showPrice,
                    vertical: false,
                    small: false,
                    onTap: () => onTap(s),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// เว้นขอบรอบผัง: ด้านบนไว้วางป้ายชื่อย่าน ด้านข้างไว้วางป้ายทางเข้า
const double kPlanTop = 30;
const double kPlanSide = 76;
const double kPlanBottom = 12;

/// ขนาดผืนผ้าใบทั้งหมด (ผัง + ขอบ)
Size get kPlanCanvas => Size(
      MarketLayout.size.width + kPlanSide * 2,
      MarketLayout.size.height + kPlanTop + kPlanBottom,
    );

/// ตัวผังจริง — พื้นย่าน + ทางเดิน + แผง + ทางเข้า
class _PlanStack extends StatelessWidget {
  final Map<String, Stall> byId;
  final String? selectedId;
  final bool showPrice;
  final bool Function(Stall)? canTap;
  final void Function(Stall) onTap;

  const _PlanStack({
    required this.byId,
    required this.selectedId,
    required this.showPrice,
    required this.canTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // พื้นตลาด + ทางเดิน
        Positioned.fill(
          child: CustomPaint(
            painter: _GroundPainter(
              ground: AppColors.surface,
              aisle: AppColors.faint,
            ),
          ),
        ),

        // พื้นสีประจำย่าน
        for (final sec in MarketLayout.sections) ..._sectionArea(sec),

        // แผงทีละช่อง — เว้นขอบรอบละนิดให้แต่ละแผงแยกกันชัด ไม่ติดเป็นพืด
        for (final slot in MarketLayout.slots)
          Positioned(
            left: slot.x + kPlanSide,
            top: slot.y + kPlanTop,
            width: slot.w,
            height: slot.h,
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: _StallTile(
                id: slot.id,
                stall: byId[slot.id],
                tappable: byId[slot.id] != null && (canTap?.call(byId[slot.id]!) ?? true),
                selected: slot.id == selectedId,
                showPrice: showPrice,
                // แผงสูงผอม (อาคารยาวหลังหมุนผัง) หมุนตัวอักษรตามแนวแผง จะได้ตัวใหญ่อ่านออก
                vertical: slot.isTall,
                small: slot.w < 60 || slot.h < 40,
                onTap: () {
                  final s = byId[slot.id];
                  if (s != null) onTap(s);
                },
              ),
            ),
          ),

        // ชื่อย่านอยู่บนสุด
        for (final sec in MarketLayout.sections) ..._sectionLabel(sec),

        // ทางเข้า (อยู่นอกกรอบผัง ชี้เข้าหาตัวตลาด)
        for (final g in MarketLayout.gates) ..._gate(g),
      ],
    );
  }

  /// ป้ายทางเข้าวางชิดขอบผังด้านที่เดินเข้ามา
  List<Widget> _gate(MarketGate g) {
    const w = 100.0, h = 34.0;
    late double left, top;
    switch (g.side) {
      case GateSide.left:
        left = kPlanSide + g.x - w - 2;
        top = kPlanTop + g.y - h / 2;
        break;
      case GateSide.right:
        left = kPlanSide + g.x + 2;
        top = kPlanTop + g.y - h / 2;
        break;
      case GateSide.top:
        left = kPlanSide + g.x - w / 2;
        top = kPlanTop + g.y - h - 2;
        break;
      case GateSide.bottom:
        left = kPlanSide + g.x - w / 2;
        top = kPlanTop + g.y + 2;
        break;
    }
    return [
      Positioned(left: left, top: top, width: w, height: h, child: _GateMark(side: g.side)),
    ];
  }

  /// กรอบย่านบนผืนผ้าใบ (เผื่อขอบรอบแผง) — null = ย่านนี้ไม่มีแผงในผัง
  Rect? _sectionRect(MarketSection sec) {
    final b = MarketLayout.boundsOfSection(sec.id);
    if (b == Rect.zero) return null;
    const pad = 12.0;
    return Rect.fromLTRB(b.left - pad + kPlanSide, b.top - pad + kPlanTop,
        b.right + pad + kPlanSide, b.bottom + pad + kPlanTop);
  }

  /// พื้นสีของย่าน
  List<Widget> _sectionArea(MarketSection sec) {
    final r = _sectionRect(sec);
    if (r == null) return const [];
    return [
      Positioned(
        left: r.left,
        top: r.top,
        width: r.width,
        height: r.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: sec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sec.color.withValues(alpha: 0.5), width: 2),
            ),
          ),
        ),
      ),
    ];
  }

  /// ป้ายชื่อย่านที่มุมซ้ายบนของย่าน — วาดหลังแผงทั้งหมด ไม่งั้นย่านข้าง ๆ ทับจนอ่านไม่ออก
  List<Widget> _sectionLabel(MarketSection sec) {
    final r = _sectionRect(sec);
    if (r == null) return const [];
    return [
      Positioned(
        left: r.left + 6,
        top: r.top - 17,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: sec.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(sec.icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(sec.label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    ];
  }
}

/// แผงหนึ่งช่อง
class _StallTile extends StatelessWidget {
  final String id;
  final Stall? stall;
  final bool tappable;
  final bool selected;
  final bool showPrice;
  final bool vertical;
  final bool small;
  final VoidCallback onTap;

  const _StallTile({
    required this.id,
    required this.stall,
    required this.tappable,
    required this.selected,
    required this.showPrice,
    required this.vertical,
    required this.small,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = stall;

    // กดไม่ได้: ยังไม่มีแผงนี้ในระบบ หรือหน้านั้นไม่ให้กดแผงสถานะนี้
    if (s == null || !tappable) {
      final sub = s == null ? 'ยังไม่เปิด' : MarketMap.labelOf(s.status);
      return Semantics(
        enabled: false,
        label: 'แผง $id $sub กดไม่ได้',
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: _content(sub, AppColors.faint, Icons.lock_rounded),
        ),
      );
    }

    final empty = s.isEmpty;
    final fill = empty ? AppColors.surface : MarketMap.colorOf(s.status);
    final fg = empty ? AppColors.primaryDark : Colors.white;
    final sub = empty
        ? (showPrice ? '฿${s.pricePerDay}' : 'ว่าง')
        : s.status == 'occupied'
            ? (s.shopName ?? 'เปิดขาย')
            : MarketMap.labelOf(s.status);

    return Semantics(
      button: true,
      selected: selected,
      label: 'แผง $id $sub',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppColors.text
                    : empty
                        ? AppColors.primary
                        : Colors.black.withValues(alpha: 0.12),
                width: selected ? 4 : (empty ? 2.5 : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.30 : 0.16),
                  blurRadius: selected ? 16 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _content(
              sub,
              fg,
              selected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(String sub, Color fg, IconData badge) {
    // ชื่อร้านยาว ๆ ทำให้ทั้งก้อนถูกย่อจนรหัสแผงอ่านไม่ออก จึงตัดไว้
    final shortSub = sub.characters.length > 12 ? '${sub.characters.take(11)}…' : sub;

    final icon = Icon(badge, size: small ? 13 : 18, color: fg);
    final label = Text(id,
        style: TextStyle(fontSize: small ? 14 : 20, fontWeight: FontWeight.w800, color: fg));
    final subText = Text(shortSub,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.92)));

    final Widget child = vertical
        ? RotatedBox(
            quarterTurns: 3,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              icon,
              const SizedBox(width: 5),
              label,
              if (!small) ...[const SizedBox(width: 8), subText],
            ]),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                icon,
                const SizedBox(width: 4),
                label,
              ]),
              if (!small) subText,
            ],
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}

/// ป้ายทางเข้า พร้อมลูกศรชี้เข้าหาตัวตลาด
class _GateMark extends StatelessWidget {
  final GateSide side;
  const _GateMark({required this.side});

  @override
  Widget build(BuildContext context) {
    // ลูกศรชี้ "เข้า" ตลาดเสมอ (ตรงข้ามกับด้านที่ป้ายอยู่)
    final arrowIcon = switch (side) {
      GateSide.left => Icons.arrow_forward_rounded,
      GateSide.right => Icons.arrow_back_rounded,
      GateSide.top => Icons.arrow_downward_rounded,
      GateSide.bottom => Icons.arrow_upward_rounded,
    };
    final arrow = Icon(arrowIcon, size: 15, color: AppColors.primaryDark);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.leafSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.meeting_room_rounded, size: 13, color: AppColors.primaryDark),
        const SizedBox(width: 4),
        Text('ทางเข้า',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
      ]),
    );
    // ป้ายกว้างตามฟอนต์ จึงย่อให้พอดีกล่องเสมอ
    final fitted = FittedBox(fit: BoxFit.scaleDown, child: chip);

    return IgnorePointer(
      child: switch (side) {
        GateSide.left => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: fitted),
            arrow,
          ]),
        GateSide.right => Row(children: [
            arrow,
            Flexible(child: fitted),
          ]),
        GateSide.top => Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: fitted),
            arrow,
          ]),
        GateSide.bottom => Column(children: [
            arrow,
            Flexible(child: fitted),
          ]),
      },
    );
  }
}

/// พื้นตลาด + ทางเดินหลัก (ไม่มีเส้นตาราง — เคยมีแล้วรกจนแผงดูกลืนกับพื้น)
class _GroundPainter extends CustomPainter {
  final Color ground;
  final Color aisle;
  const _GroundPainter({required this.ground, required this.aisle});

  @override
  void paint(Canvas canvas, Size size) {
    // พื้นตลาดคือเฉพาะกรอบผัง ไม่รวมขอบที่เว้นไว้วางป้าย
    final rect = Rect.fromLTWH(
      kPlanSide,
      kPlanTop,
      MarketLayout.size.width,
      MarketLayout.size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = ground,
    );

    // ทางเดินหลักระหว่างแถว
    final walk = Paint()
      ..color = aisle.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final a in MarketLayout.aisles) {
      _dashedLine(
        canvas,
        Offset(a[0] + kPlanSide, a[1] + kPlanTop),
        Offset(a[2] + kPlanSide, a[3] + kPlanTop),
        walk,
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 10.0, gap = 8.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final len = math.min(dash, total - d);
      canvas.drawLine(a + dir * d, a + dir * (d + len), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GroundPainter old) =>
      old.ground != ground || old.aisle != aisle;
}

/// คำอธิบายด้านบน: กดได้/กดไม่ได้ + สีสถานะพร้อมจำนวน
class _Legend extends StatelessWidget {
  final Map<String, int> counts;
  final String lockedHint;
  const _Legend({required this.counts, required this.lockedHint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(
            child: _LegendSample(tappable: true, label: 'กดได้', hint: 'มีเงา · รูปนิ้วแตะ'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LegendSample(tappable: false, label: 'กดไม่ได้', hint: lockedHint),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 8, children: [
          _StatusDot(label: 'เปิดขาย', kind: 'occupied', count: counts['occupied']!),
          _StatusDot(label: 'ว่าง', kind: 'empty', count: counts['empty']!),
          _StatusDot(label: 'ค้างชำระ', kind: 'due', count: counts['due']!),
          _StatusDot(label: 'ปิดปรับปรุง', kind: 'closed', count: counts['closed']!),
        ]),
      ],
    );
  }
}

class _LegendSample extends StatelessWidget {
  final bool tappable;
  final String label;
  final String hint;
  const _LegendSample({required this.tappable, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 30,
        decoration: BoxDecoration(
          color: tappable ? AppColors.surface : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tappable ? AppColors.primary : AppColors.border,
            width: tappable ? 2 : 1,
          ),
          boxShadow: tappable
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(tappable ? Icons.touch_app_rounded : Icons.lock_rounded,
            size: 15, color: tappable ? AppColors.primaryDark : AppColors.faint),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          Text(hint,
              maxLines: 2,
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.25)),
        ]),
      ),
    ]);
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final String kind;
  final int count;
  const _StatusDot({required this.label, required this.kind, required this.count});

  @override
  Widget build(BuildContext context) {
    final empty = kind == 'empty';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: empty ? AppColors.surface : MarketMap.colorOf(kind),
          borderRadius: BorderRadius.circular(4),
          border: empty ? Border.all(color: AppColors.primary, width: 1.6) : null,
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

/// ผังตลาดแบบเต็มจอ — เปิดจากปุ่ม "ดูเต็มจอ"
///
/// ผังจริงมีแผงเล็กหลายสิบช่อง ย่อลงในการ์ดแล้วอ่านตัวหนังสือไม่ออก
/// หน้านี้จึงขยายให้เต็มความสูงจอแล้วเลื่อนดูซ้าย–ขวาได้
class MarketMapFullScreen extends StatefulWidget {
  final List<Stall> stalls;
  final String? selectedId;
  final bool showPrice;
  final bool Function(Stall)? canTap;
  final void Function(Stall) onTap;

  const MarketMapFullScreen({
    super.key,
    required this.stalls,
    required this.onTap,
    this.selectedId,
    this.showPrice = false,
    this.canTap,
  });

  @override
  State<MarketMapFullScreen> createState() => _MarketMapFullScreenState();
}

class _MarketMapFullScreenState extends State<MarketMapFullScreen> {
  final _tc = TransformationController();
  late String? _sel = widget.selectedId;
  bool _fitted = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  /// เริ่มต้นให้ผังเต็มความสูงจอ (ไม่ใช่เต็มความกว้าง) จะได้ตัวใหญ่อ่านออก
  void _fitHeight(Size viewport) {
    if (_fitted) return;
    _fitted = true;
    final scale = viewport.height / kPlanCanvas.height;
    _tc.value = Matrix4.identity()..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final s in widget.stalls) s.id: s};
    final sel = _sel == null ? null : byId[_sel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผังตลาดแม่โจ้'),
        actions: [
          IconButton(
            tooltip: 'พอดีจอ',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: () {
              _fitted = false;
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                _fitHeight(Size(c.maxWidth, c.maxHeight));
                return InteractiveViewer(
                  transformationController: _tc,
                  constrained: false,
                  minScale: 0.2,
                  maxScale: 6,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: SizedBox(
                    width: kPlanCanvas.width,
                    height: kPlanCanvas.height,
                    child: _PlanStack(
                      byId: byId,
                      selectedId: _sel,
                      showPrice: widget.showPrice,
                      canTap: widget.canTap,
                      onTap: (s) {
                        setState(() => _sel = s.id);
                        widget.onTap(s);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // แถบสรุปแผงที่เลือก
          if (sel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MarketLayout.sectionOfStall(sel.id)?.color ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(sel.id,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sel.shopName ?? 'แผงว่าง',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                            '${MarketLayout.sectionOfStall(sel.id)?.label ?? sel.categoryLabel}'
                            ' · ฿${sel.pricePerDay}/วัน',
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text(MarketMap.labelOf(sel.status),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          // colorOf('empty') เป็นสีพื้นจาง ใช้กับตัวหนังสือแล้วมองไม่เห็น
                          color: sel.isEmpty ? AppColors.primary : MarketMap.colorOf(sel.status))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
