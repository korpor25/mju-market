import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// ปุ่มเลือกช่วงเวลาของรายงาน (ใช้ร่วมกันทั้งฝั่งผู้ขายและแอดมิน)
class PeriodSelector extends StatelessWidget {
  final SalePeriod value;
  final ValueChanged<SalePeriod> onChanged;
  const PeriodSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<SalePeriod>(
        segments: [
          for (final p in SalePeriod.values)
            ButtonSegment(value: p, label: Text(p.labelTh, style: TextStyle(fontSize: 12.5))),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
        ),
      ),
    );
  }
}

/// ข้อมูล 1 แท่งของกราฟ
class BarDatum {
  final String label; // ป้ายใต้แท่ง เช่น "5 ส.ค."
  final double value;
  const BarDatum(this.label, this.value);
}

/// กราฟแท่งขนาดเล็ก (เขียนเอง ไม่ต้องพึ่ง package เพิ่ม)
///
/// - แท่งที่ยอดสูงสุดจะเน้นสีเข้ม
/// - แตะที่แท่งเพื่อดูตัวเลขของวันนั้น
class MiniBarChart extends StatefulWidget {
  final List<BarDatum> bars;
  final double height;

  /// แสดงป้ายทุก ๆ กี่แท่ง (ใช้เมื่อแท่งเยอะจนป้ายชนกัน)
  final int labelEvery;

  const MiniBarChart({
    super.key,
    required this.bars,
    this.height = 150,
    this.labelEvery = 1,
  });

  @override
  State<MiniBarChart> createState() => _MiniBarChartState();
}

class _MiniBarChartState extends State<MiniBarChart> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    if (bars.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('ไม่มีข้อมูล', style: TextStyle(color: AppColors.muted))),
      );
    }

    final maxV = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    final sel = (_sel != null && _sel! < bars.length) ? bars[_sel!] : null;
    // เมื่อยังไม่ได้เลือกแท่งไหน ให้โชว์วันล่าสุดเป็นค่าเริ่มต้น
    final shown = sel ?? bars.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(money(shown.value),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(shown.label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
        ]),
        SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bars.length; i++)
                Expanded(
                  child: _Bar(
                    datum: bars[i],
                    maxValue: maxV,
                    selected: _sel == i,
                    highlight: maxV > 0 && bars[i].value == maxV,
                    showLabel: i % widget.labelEvery == 0 || i == bars.length - 1,
                    // ยิ่งแท่งเยอะยิ่งไล่ช้าลงเล็กน้อย ให้ดูลื่นตอนเปิดหน้า
                    delayMs: i * (bars.length > 12 ? 12 : 35),
                    onTap: () => setState(() => _sel = _sel == i ? null : i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final BarDatum datum;
  final double maxValue;
  final bool selected;
  final bool highlight;
  final bool showLabel;
  final int delayMs;
  final VoidCallback onTap;

  const _Bar({
    required this.datum,
    required this.maxValue,
    required this.selected,
    required this.highlight,
    required this.showLabel,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (datum.value / maxValue).clamp(0.0, 1.0);
    final color = selected
        ? AppColors.accent
        : (highlight ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.55));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: Duration(milliseconds: 620 + delayMs),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      // เหลือความสูงขั้นต่ำไว้ 3px ให้เห็นว่าวันนั้นมีอยู่ในกราฟ
                      height: (c.maxHeight * v).clamp(3.0, c.maxHeight),
                      decoration: BoxDecoration(
                        color: datum.value <= 0 ? AppColors.border : color,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            SizedBox(
              height: 14,
              child: showLabel
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        datum.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: selected ? AppColors.accent : AppColors.faint,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// แถวจัดอันดับพร้อมแถบสัดส่วน (สินค้าขายดี / ร้านขายดี)
class RankBarRow extends StatelessWidget {
  final int rank;
  final String label;
  final String trailing;
  final String? subtitle;
  final double ratio; // 0..1 เทียบกับอันดับ 1

  const RankBarRow({
    super.key,
    required this.rank,
    required this.label,
    required this.trailing,
    this.subtitle,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3 ? AppColors.accent : AppColors.muted;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppColors.accentSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('$rank',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: medal)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(trailing,
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13.5)),
          ]),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
              duration: Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation(
                    rank == 1 ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
