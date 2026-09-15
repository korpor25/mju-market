import '../services/cloudinary.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'animations.dart';

LinearGradient get brandGradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primaryLight, AppColors.primaryDark],
    );

/// ใส่ลูกน้ำหลักพัน เช่น 12000 -> 12,000
String thousands(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final buf = StringBuffer(neg ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// จำนวนเงินบาท เช่น 12000 -> ฿12,000 (ปัดเป็นจำนวนเต็ม)
String money(num v) => '฿${thousands(v.round())}';

/// โลโก้แอป (ภาพ assets/images/logo.png — มุมนอกกรอบโปร่งใสอยู่แล้ว)
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const AppLogo({super.key, this.size = 72, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.06),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png',
              width: size, height: size, filterQuality: FilterQuality.medium),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text('Maejo Market',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text('ตลาดแม่โจ้', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ],
    );
  }
}

/// หัวข้อ section
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  SectionTitle(this.title, {super.key, this.icon = Icons.circle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// การ์ดพื้นฐาน (ขอบ + เงาอ่อน) — กดแล้วมีเอฟเฟกต์ย่อเล็กน้อย
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: Duration(milliseconds: 130),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pressed ? AppColors.primaryLight : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A16321E),
            blurRadius: _pressed ? 8 : 14,
            offset: Offset(0, _pressed ? 3 : 6),
          ),
        ],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return content;
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: content,
        ),
      ),
    );
  }
}

// ==================== รูปแบบการจัดวาง (layout formats) ====================
//
// เดิมทุกอย่างในแอปเป็น "การ์ดใบเดี่ยว" เรียงต่อกันลงมา ทำให้หน้าจอเต็มไปด้วย
// กรอบซ้อนกรอบ อ่านลำดับความสำคัญไม่ออก ชุดด้านล่างแยกเป็น 3 รูปแบบชัดเจน:
//
//   HeroPanel   — ค่าที่สำคัญที่สุดของหน้า มีใบเดียวเท่านั้น
//   StatStrip   — ตัวเลขรอง 2–4 ค่า อยู่ในกรอบเดียวคั่นด้วยเส้น (ไม่ใช่กรอบละใบ)
//   GroupedCard — รายการที่เป็นพวกเดียวกัน อยู่ในกรอบเดียวคั่นด้วยเส้น
//
// ผลคือจำนวนกรอบต่อหน้าลดลงมาก เหลือกรอบเฉพาะตอนที่ "เปลี่ยนเรื่อง" จริง ๆ

/// แผงหลักของหน้า — ค่าที่สำคัญที่สุดหนึ่งค่า พร้อมปุ่มลงมือทำ
///
/// ใช้ได้หน้าละใบเดียว ถ้ามีสองใบแปลว่ายังไม่ได้ตัดสินใจว่าอะไรสำคัญที่สุด
class HeroPanel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// ข้อความรองใต้ค่า เช่น "3 บิลวันนี้"
  final String? caption;
  final Widget? badge;
  final List<Widget> actions;

  const HeroPanel({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.badge,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            if (badge != null) badge!,
          ]),
          SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.05,
              )),
          if (caption != null) ...[
            SizedBox(height: 2),
            Text(caption!, style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          ],
          if (actions.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ปุ่มสำหรับวางใน [HeroPanel] (พื้นขาว/โปร่ง ให้อ่านออกบนพื้นเขียว)
class HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const HeroAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.primaryDark : Colors.white;
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: Colors.white38),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: fg),
            SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ตัวเลขหนึ่งช่องใน [StatStrip]
class StatItem {
  final IconData? icon;
  final String label;
  final String? value;

  /// ถ้าใส่ [countTo] ตัวเลขจะนับขึ้นจาก 0 ตอนเข้าหน้า
  final int? countTo;
  final String Function(int)? format;
  final Color? color;

  const StatItem({
    required this.label,
    this.value,
    this.icon,
    this.countTo,
    this.format,
    this.color,
  });
}

/// ตัวเลขรองหลายค่าในกรอบเดียว คั่นด้วยเส้นแนวตั้ง
///
/// แทนการวางการ์ด KPI เป็นตาราง 2x2 ซึ่งกินพื้นที่และทำให้ทุกค่าดูสำคัญเท่ากัน
class StatStrip extends StatelessWidget {
  final List<StatItem> items;
  const StatStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(width: 1, thickness: 1, color: AppColors.border, indent: 2, endIndent: 2),
              Expanded(child: _cell(items[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell(StatItem it) {
    final c = it.color ?? AppColors.text;
    final valueStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c, height: 1.1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (it.icon != null) ...[
            Icon(it.icon, size: 15, color: it.color ?? AppColors.muted),
            SizedBox(height: 5),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: it.countTo != null
                ? AnimatedCount(it.countTo!, style: valueStyle, format: it.format)
                : Text(it.value ?? '—', style: valueStyle),
          ),
          SizedBox(height: 3),
          Text(it.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.2)),
        ],
      ),
    );
  }
}

/// กรอบเดียวที่รวมหลายแถวไว้ด้วยกัน คั่นด้วยเส้นบาง
///
/// ใช้แทนการวาง AppCard ทีละใบต่อหนึ่งรายการ — ลดกรอบซ้อนกรอบลงมาก
class GroupedCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry rowPadding;

  const GroupedCard({
    super.key,
    required this.children,
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            Container(
              padding: rowPadding,
              decoration: BoxDecoration(
                border: i == children.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

/// แถวมาตรฐานของแอป: ภาพ/ไอคอน + ชื่อ + คำอธิบาย + ท้ายแถว
///
/// ใช้รูปแบบเดียวกันทั้งรายการร้าน สินค้า ยอดขาย และผู้ใช้ เพื่อให้ผู้ใช้
/// เรียนรู้ครั้งเดียวแล้วอ่านทุกหน้าออก
class AppListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? note;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.note,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(children: [
      leading,
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (subtitle != null)
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            if (note != null)
              Text(note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.faint, fontSize: 11.5)),
          ],
        ),
      ),
      if (trailing != null) ...[SizedBox(width: 8), trailing!],
    ]);
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}

/// ข้อความบอกสถานะว่าง (ไม่มีข้อมูล) พร้อมทางออกให้ผู้ใช้ทำต่อ
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(children: [
          Icon(icon, size: 30, color: AppColors.faint),
          SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
          if (action != null) ...[SizedBox(height: 12), action!],
        ]),
      ),
    );
  }
}

/// ป้ายสถานะ (pill)
class StatusPill extends StatelessWidget {
  final String text;
  final String tone; // ok / warn / bad / muted
  StatusPill(this.text, {super.key, this.tone = 'ok'});

  @override
  Widget build(BuildContext context) {
    Color fg, bg;
    switch (tone) {
      case 'warn':
        fg = AppColors.warn; bg = AppColors.warnSoft; break;
      case 'bad':
        fg = AppColors.bad; bg = AppColors.badSoft; break;
      case 'muted':
        fg = AppColors.muted; bg = AppColors.surface2; break;
      default:
        fg = AppColors.ok; bg = AppColors.okSoft;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// การ์ด KPI (แดชบอร์ด) — รองรับตัวเลขนับขึ้น (countTo)
class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? delta;
  final int? countTo;
  final String Function(int)? countFormat;
  KpiCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.value = '',
    this.delta,
    this.countTo,
    this.countFormat,
  });

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return AppCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              SizedBox(width: 8),
              Flexible(child: Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
            ],
          ),
          SizedBox(height: 8),
          countTo != null
              ? AnimatedCount(countTo!, style: valueStyle, format: countFormat)
              : Text(value, style: valueStyle),
          if (delta != null) ...[
            SizedBox(height: 2),
            Row(children: [
              Icon(Icons.trending_up_rounded, size: 13, color: AppColors.ok),
              SizedBox(width: 3),
              Text(delta!, style: TextStyle(fontSize: 11.5, color: AppColors.ok, fontWeight: FontWeight.w700)),
            ]),
          ],
        ],
      ),
    );
  }
}

/// helper: กล่องไอคอนวงกลม/มน
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  IconChip(this.icon, {super.key, required this.color, required this.bg, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// รูปจากอินเทอร์เน็ต + fallback เป็นไอคอนเมื่อไม่มีรูป/โหลดไม่ได้
class NetImage extends StatelessWidget {
  final String url;
  final IconData fallback;
  final double width;
  final double height;
  final double radius;
  final Color? bg;
  final Color? iconColor;
  final double? iconSize;

  NetImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fallback = Icons.storefront_rounded,
    this.radius = 14,
    this.bg,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgC = bg ?? AppColors.leafSoft;
    final iconC = iconColor ?? AppColors.primary;
    Widget fb() => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: bgC, borderRadius: BorderRadius.circular(radius)),
          alignment: Alignment.center,
          child: Icon(fallback, color: iconC, size: iconSize ?? width * 0.5),
        );
    if (url.trim().isEmpty) return fb();
    // ถ้าเป็นลิงก์ Cloudinary ให้ขอขนาดที่พอดีกับกล่อง จะได้ไม่โหลดไฟล์เต็มมาย่อทิ้ง
    // ลิงก์จากที่อื่นคืนค่าเดิม ไม่มีผลอะไร
    final src = Cloudinary.sized(url, width: (width * 2).clamp(200, 1600).round());
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fb(),
        loadingBuilder: (c, child, prog) => prog == null
            ? child
            : Container(
                width: width,
                height: height,
                decoration: BoxDecoration(color: bgC, borderRadius: BorderRadius.circular(radius)),
                alignment: Alignment.center,
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      ),
    );
  }
}

void showSnack(BuildContext context, String msg, {bool bad = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(bad ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: bad ? AppColors.bad : AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}
