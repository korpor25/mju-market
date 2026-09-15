import 'package:flutter/material.dart';

import '../services/cloudinary.dart';
import '../theme/app_colors.dart';

/// ========================================================================
/// ชุด UI แบบ "หน้าร้านออนไลน์" — ปุ่มกลมลอยบนรูป, แถบเมนูแคปซูลลอย,
/// ชิปหมวดหมู่มีรูป, การ์ดสินค้าแบบตาราง
///
/// ใช้สีเดิมของแบรนด์ทั้งหมด (AppColors) เปลี่ยนเฉพาะรูปทรง/การจัดวาง
/// ========================================================================

/// รัศมีโค้งมาตรฐานของชุดนี้
const double kPillRadius = 999;
const double kTileRadius = 20;
const double kPanelRadius = 26;

/// ความสูงที่แถบเมนูลอยกินพื้นที่ — เอาไว้เว้น padding ล่างของหน้าที่เลื่อนได้
double navBarInset(BuildContext context) =>
    86 + MediaQuery.of(context).padding.bottom;

/// เงานุ่มแบบเดียวกันทั้งชุด
List<BoxShadow> softShadow({double blur = 18, double y = 8, double opacity = 0.10}) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];

/// รูปที่ยืดเต็มกล่องที่ครอบอยู่ + fallback เป็นไอคอนเมื่อไม่มีรูป
class CoverImage extends StatelessWidget {
  final String url;
  final IconData fallback;
  final Color? bg;
  final Color? iconColor;
  final double iconSize;

  const CoverImage({
    super.key,
    required this.url,
    this.fallback = Icons.storefront_rounded,
    this.bg,
    this.iconColor,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final bgC = bg ?? AppColors.leafSoft;
    Widget fb() => Container(
          color: bgC,
          alignment: Alignment.center,
          child: Icon(fallback, color: iconColor ?? AppColors.primary, size: iconSize),
        );
    if (url.trim().isEmpty) return fb();
    return Image.network(
      Cloudinary.sized(url, width: 800),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fb(),
      loadingBuilder: (c, child, prog) => prog == null
          ? child
          : Container(
              color: bgC,
              alignment: Alignment.center,
              child: const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

/// ปุ่มกลมลอย (วางทับรูป header ได้) — พื้นขาวโปร่งเล็กน้อย
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  /// ใช้โทนกลับด้าน (พื้นสีแบรนด์ ไอคอนขาว) เช่นปุ่มตัวกรองที่ต้องเด่น
  final bool solid;
  final Widget? badge;

  const CircleIconButton(
    this.icon, {
    super.key,
    this.onTap,
    this.tooltip,
    this.size = 46,
    this.solid = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bg = solid ? AppColors.primary : AppColors.surface.withValues(alpha: 0.92);
    final fg = solid ? Colors.white : AppColors.text;
    Widget btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: softShadow(blur: 12, y: 4, opacity: 0.12),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: size * 0.46, color: fg),
        ),
      ),
    );
    if (badge != null) {
      btn = Stack(clipBehavior: Clip.none, children: [
        btn,
        Positioned(right: -2, top: -2, child: badge!),
      ]);
    }
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// ปุ่มแคปซูล — ใช้เป็นปุ่ม "ติดตาม" บน header หรือ CTA หลักของหน้า
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// true = พื้นทึบสีแบรนด์ / false = พื้นขาวโปร่งแบบปุ่มลอยบนรูป
  final bool filled;
  final double height;
  final Color? color;

  const PillButton(
    this.label, {
    super.key,
    this.icon,
    this.onTap,
    this.filled = false,
    this.height = 46,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    final bg = filled ? base : AppColors.surface.withValues(alpha: 0.92);
    final fg = filled ? Colors.white : AppColors.text;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kPillRadius),
        boxShadow: softShadow(blur: 12, y: 4, opacity: 0.12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kPillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.42),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// ชิปหมวดหมู่แบบมีรูป/ไอคอนนำหน้า (แถวเลื่อนแนวนอนใต้ header)
class CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final String imageUrl;
  final bool selected;
  final VoidCallback? onTap;
  final Color? tint;

  const CategoryPill({
    super.key,
    required this.label,
    this.icon = Icons.storefront_rounded,
    this.imageUrl = '',
    this.selected = false,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? AppColors.primary;
    final bg = selected ? accent : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.text;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kPillRadius),
        border: Border.all(color: selected ? accent : AppColors.border),
        boxShadow: softShadow(blur: 10, y: 4, opacity: selected ? 0.14 : 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kPillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CoverImage(
                    url: imageUrl,
                    fallback: icon,
                    iconSize: 20,
                    bg: selected ? Colors.white.withValues(alpha: 0.22) : AppColors.leafSoft,
                    iconColor: selected ? Colors.white : accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// ชิปตัวกรอง/เรียงลำดับแบบเตี้ย (แถวใต้ช่องค้นหา)
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;

  /// ใส่เมื่อชิปเปิดเมนูให้เลือก (จะมีลูกศรลงท้ายชิป)
  final bool dropdown;
  final VoidCallback? onTap;

  const FilterPill(
    this.label, {
    super.key,
    this.selected = false,
    this.icon,
    this.dropdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.text;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kPillRadius),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kPillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13.5)),
              if (dropdown) ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fg),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// ช่องค้นหาแบบแคปซูล
class SearchPill extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchPill({
    super.key,
    this.hint = 'ค้นหาร้านค้า / สินค้า…',
    this.onChanged,
    this.onTap,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(kPillRadius),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        readOnly: onChanged == null,
        onTap: onTap,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hint,
          filled: false,
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// แถวดาว (อ่านอย่างเดียว) รองรับครึ่งดาว
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  const StarRow({super.key, required this.rating, this.size = 14, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final pos = i + 1;
        IconData ic;
        if (rating >= pos) {
          ic = Icons.star_rounded;
        } else if (rating >= pos - 0.5) {
          ic = Icons.star_half_rounded;
        } else {
          ic = Icons.star_border_rounded;
        }
        return Icon(ic, size: size, color: color ?? AppColors.accent);
      }),
    );
  }
}

/// ดาว + จำนวนรีวิว ในบรรทัดเดียว (ใต้ชื่อในการ์ดตาราง)
class RatingLine extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  const RatingLine({super.key, required this.rating, this.count = 0, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      StarRow(rating: rating, size: size),
      const SizedBox(width: 5),
      Text(count > 0 ? '($count)' : '(ใหม่)',
          style: TextStyle(
              fontSize: size - 0.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
    ]);
  }
}

/// การ์ดแบบตาราง: รูปใหญ่มุมมน + ปุ่มหัวใจลอยมุมขวาล่างของรูป + ชื่อ/คะแนน/ราคา
class TileCard extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String? subtitle;

  /// แถวคะแนน (ถ้ามี) แสดงใต้ชื่อ
  final double? rating;
  final int reviewCount;

  /// บรรทัดล่างสุด เช่น ราคา หรือ เลขแผง
  final String? trailingText;
  final Color? trailingColor;
  final VoidCallback? onTap;

  /// ปุ่มหัวใจ — ส่ง null ถ้าไม่ต้องการ
  final bool? favorite;
  final VoidCallback? onFavorite;

  /// ป้ายมุมซ้ายบนของรูป เช่น "ปิดปรับปรุง"
  final Widget? badge;

  const TileCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.fallbackIcon = Icons.storefront_rounded,
    this.subtitle,
    this.rating,
    this.reviewCount = 0,
    this.trailingText,
    this.trailingColor,
    this.onTap,
    this.favorite,
    this.onFavorite,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(kTileRadius),
                  child: CoverImage(
                      url: imageUrl, fallback: fallbackIcon, bg: AppColors.surface2),
                ),
                if (badge != null) Positioned(left: 10, top: 10, child: badge!),
                if (favorite != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _HeartButton(active: favorite!, onTap: onFavorite),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          if (rating != null) ...[
            const SizedBox(height: 4),
            RatingLine(rating: rating!, count: reviewCount),
          ],
          if (trailingText != null) ...[
            const SizedBox(height: 4),
            Text(trailingText!,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: trailingColor ?? AppColors.text)),
          ],
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _HeartButton({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 20,
            color: active ? AppColors.bad : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// แผงมุมโค้งใหญ่ที่ห่อเนื้อหาหนึ่งเรื่อง (เช่น "แนะนำสำหรับคุณ")
class SoftPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SoftPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(kPanelRadius),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// หัวข้อใหญ่ประจำหน้า (ตัวหนาขนาดใหญ่ + ปุ่มกลมท้ายแถว)
class PageHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const PageHeading(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

/// หนึ่งปุ่มในแถบเมนูลอย
class NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.label, {this.activeIcon, this.badge = 0});
}

/// แถบเมนูแคปซูลลอยเหนือเนื้อหา (แทน NavigationBar เต็มความกว้าง)
///
/// ต้องลอยทับเนื้อหา จึงใช้คู่กับ [FloatingNavScaffold] และเว้น padding
/// ล่างของ list ด้วย [navBarInset]
class FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<NavItem> items;

  /// ปุ่มกลมแยกทางซ้ายของแคปซูล (เช่นปุ่มย้อนกลับ)
  final Widget? leading;

  const FloatingNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Flexible(
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(kPillRadius),
                  boxShadow: softShadow(blur: 22, y: 8, opacity: 0.16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Flexible(child: _tab(i, items[i])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(int i, NavItem it) {
    final on = i == index;
    Widget icon = Icon(
      on ? (it.activeIcon ?? it.icon) : it.icon,
      size: 24,
      color: on ? AppColors.primary : AppColors.muted,
    );
    if (it.badge > 0) {
      icon = Badge(
        label: Text('${it.badge}'),
        backgroundColor: AppColors.bad,
        child: icon,
      );
    }
    return Tooltip(
      message: it.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kPillRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 50,
            width: 54,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: on ? AppColors.leafSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(kPillRadius),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

/// โครงหน้าที่มีแถบเมนูลอย
///
/// [floatOverContent] = true  → เนื้อหาเต็มจอ แถบเมนูลอยทับ (หน้าที่ออกแบบ
/// padding ล่างเองด้วย [navBarInset] เช่นฝั่งผู้ซื้อ)
/// [floatOverContent] = false → แถบเมนูกินพื้นที่ล่างตามปกติ ใช้กับหน้าเดิม
/// ที่ยังไม่ได้เผื่อ padding ไว้ (ฝั่งผู้ขาย/แอดมิน)
class FloatingNavScaffold extends StatelessWidget {
  final Widget body;

  /// ปกติคือ [FloatingNavBar] — เปิดกว้างไว้เผื่อต้องห่อ ListenableBuilder
  final Widget navBar;
  final bool floatOverContent;

  const FloatingNavScaffold({
    super.key,
    required this.body,
    required this.navBar,
    this.floatOverContent = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!floatOverContent) {
      return Scaffold(body: body, bottomNavigationBar: navBar);
    }
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        body,
        Positioned(left: 0, right: 0, bottom: 0, child: navBar),
      ]),
    );
  }
}

/// หัวเรื่องแบบเลื่อนแล้วหด (รูปปกเต็มความกว้าง + ปุ่มกลมลอย + ชื่อกลางภาพ)
class HeroHeader extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String? subtitle;

  /// ปุ่มกลมมุมซ้ายบน (ย้อนกลับ/เมนู)
  final List<Widget> leadingActions;

  /// ปุ่มมุมขวาบน (ติดตาม/แชร์)
  final List<Widget> trailingActions;
  final double height;
  final Widget? bottom;

  const HeroHeader({
    super.key,
    required this.imageUrl,
    required this.title,
    this.fallbackIcon = Icons.storefront_rounded,
    this.subtitle,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.height = 300,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: height + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Stack(fit: StackFit.expand, children: [
              // ไม่มีรูปปก → ใช้พื้นไล่สีของแบรนด์เปล่า ๆ ไม่วางไอคอนใหญ่กลางภาพ
              // เพราะจะไปชนกับชื่อที่อยู่กลางจอพอดี
              if (imageUrl.trim().isEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                  ),
                )
              else
                CoverImage(
                  url: imageUrl,
                  fallback: fallbackIcon,
                  iconSize: 84,
                  bg: AppColors.primary,
                  iconColor: Colors.white70,
                ),
              // เฉดมืดบาง ๆ ด้านบน ให้ปุ่มกลม/ตัวอักษรอ่านออกไม่ว่ารูปจะสว่างแค่ไหน
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0x0D000000), Color(0x40000000)],
                    stops: [0, 0.42, 0.78],
                  ),
                ),
              ),
              // ขอบล่างของรูปละลายเข้าเป็นสีพื้นของการ์ดที่ทับอยู่
              // ถ้าไม่มีชั้นนี้ รอยต่อรูป↔การ์ดจะเป็นเส้นตัดแข็ง ๆ ดูไม่เนียน
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.bg.withValues(alpha: 0),
                      AppColors.bg.withValues(alpha: 0.55),
                      AppColors.bg,
                    ],
                    stops: const [0.68, 0.88, 1],
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 10,
            child: Row(children: [
              for (final a in leadingActions) ...[a, const SizedBox(width: 10)],
              const Spacer(),
              for (final a in trailingActions) ...[const SizedBox(width: 10), a],
            ]),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: kSheetLip + 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      shadows: [Shadow(color: Color(0x66000000), blurRadius: 12)],
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Color(0x66000000), blurRadius: 10)],
                      )),
                ],
                if (bottom != null) ...[const SizedBox(height: 12), bottom!],
              ],
            ),
          ),

          // ขอบบนของ "แผ่นเนื้อหา" ที่เลื่อนขึ้นมาทับรูปปก
          const Positioned(left: 0, right: 0, bottom: 0, child: SheetLip()),
        ],
      ),
    );
  }
}

/// ความสูงของขอบแผ่นเนื้อหาที่ทับรูปปกอยู่
const double kSheetLip = 26;

/// ขอบบนของแผ่นเนื้อหา — มุมโค้งด้านบน + เงาทอดขึ้นไปบนรูป
///
/// วางไว้ท้าย Stack ของรูปปก ทำให้ดูเหมือนเนื้อหาด้านล่าง "เลื่อนขึ้นมาทับ" รูป
/// (สีเดียวกับพื้นหน้า จึงต่อเนื่องกับเนื้อหาที่อยู่ถัดลงไปพอดี)
class SheetLip extends StatelessWidget {
  final double height;
  final double radius;
  final Color? color;

  const SheetLip({super.key, this.height = kSheetLip, this.radius = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color ?? AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -5),
            ),
          ],
        ),
      ),
    );
  }
}
