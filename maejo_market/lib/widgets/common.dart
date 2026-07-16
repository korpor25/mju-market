import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primaryLight, AppColors.primaryDark],
);

/// โลโก้แอป (ไอคอนร้าน + ใบไม้)
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
            gradient: brandGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.storefront_rounded, color: Colors.white, size: size * 0.5),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          const Text('Maejo Market',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Text('ตลาดแม่โจ้', style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
  const SectionTitle(this.title, {super.key, this.icon = Icons.circle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// การ์ดพื้นฐาน (ขอบ + เงาอ่อน)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A16321E), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: content);
  }
}

/// ป้ายสถานะ (pill)
class StatusPill extends StatelessWidget {
  final String text;
  final String tone; // ok / warn / bad / muted
  const StatusPill(this.text, {super.key, this.tone = 'ok'});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// การ์ด KPI (แดชบอร์ด)
class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? delta;
  const KpiCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.ok),
              const SizedBox(width: 3),
              Text(delta!, style: const TextStyle(fontSize: 11.5, color: AppColors.ok, fontWeight: FontWeight.w700)),
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
  const IconChip(this.icon, {super.key, required this.color, required this.bg, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

void showSnack(BuildContext context, String msg, {bool bad = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(bad ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: bad ? AppColors.bad : AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}
