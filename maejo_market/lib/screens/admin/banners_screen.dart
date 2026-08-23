import '../../widgets/banner_carousel.dart';
import 'package:flutter/material.dart';
import '../../models/promo_banner.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/image_field.dart';

/// จัดการแบนเนอร์หน้าแรกฝั่งผู้บริโภค — เพิ่ม/แก้/ลบ/ปิดชั่วคราว/เรียงลำดับ
class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการแบนเนอร์หน้าแรก')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มแบนเนอร์'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          // เรียงตามลำดับที่ตั้งไว้ รวมอันที่ปิดอยู่ด้วย แอดมินจะได้เห็นครบ
          final list = [...appState.banners]..sort((a, b) => a.order.compareTo(b.order));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // ตัวจริงที่ผู้ซื้อเห็น ไม่ใช่ของจำลอง — ใช้ widget ตัวเดียวกับหน้าแรก
              // บัญชีแอดมินไม่มีบทบาทผู้บริโภค จึงเปิดหน้าแรกฝั่งผู้ซื้อไม่ได้
              // ถ้าไม่มีตรงนี้ ตั้งค่าแบนเนอร์แล้วจะดูผลไม่ได้เลย
              SectionTitle('ตัวอย่างที่ผู้ซื้อเห็น', icon: Icons.visibility_rounded),
              const BannerCarousel(),
              SectionTitle('แบนเนอร์ทั้งหมด', icon: Icons.view_carousel_rounded),
              if (list.isEmpty)
                _empty()
              else
                for (var i = 0; i < list.length; i++) ...[
                  _row(list[i], i, list.length),
                  if (i != list.length - 1) const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 56, color: AppColors.faint),
            const SizedBox(height: 12),
            Text('ยังไม่มีแบนเนอร์',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('หน้าแรกจะแสดงพื้นหลังไล่สีของแบรนด์ไปก่อน',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _row(PromoBanner b, int i, int total) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Opacity(
              opacity: b.active ? 1 : 0.45,
              child: LayoutBuilder(
                builder: (_, c) => NetImage(
                  url: b.imageUrl,
                  fallback: Icons.image_outlined,
                  width: c.maxWidth,
                  height: 110,
                  radius: 0,
                  iconSize: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.title.isEmpty ? '(ไม่มีหัวข้อ)' : b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (b.subtitle.isNotEmpty)
                        Text(b.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _tag('ลำดับ ${b.order + 1}', AppColors.primary, AppColors.leafSoft),
                        if (!b.active) _tag('ปิดอยู่', AppColors.muted, AppColors.surface2),
                        if (b.hasLink) _tag('ลิงก์ร้าน', AppColors.ok, AppColors.okSoft),
                      ]),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: 'เลื่อนขึ้น',
                        icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                        onPressed: i == 0 ? null : () => _move(b, -1),
                      ),
                      IconButton(
                        tooltip: 'เลื่อนลง',
                        icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                        onPressed: i == total - 1 ? null : () => _move(b, 1),
                      ),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: b.active ? 'ปิดชั่วคราว' : 'เปิดใช้งาน',
                        icon: Icon(
                            b.active ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 20),
                        onPressed: () => appState.saveBanner(b.copyWith(active: !b.active)),
                      ),
                      IconButton(
                        tooltip: 'แก้ไข',
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _edit(b),
                      ),
                      IconButton(
                        tooltip: 'ลบ',
                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.bad),
                        onPressed: () => _confirmDelete(b),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  /// สลับลำดับกับตัวที่อยู่ติดกัน แล้วบันทึกทั้งคู่
  Future<void> _move(PromoBanner b, int delta) async {
    final list = [...appState.banners]..sort((a, c) => a.order.compareTo(c.order));
    final i = list.indexWhere((x) => x.id == b.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return;
    final other = list[j];
    await appState.saveBanner(b.copyWith(order: other.order));
    await appState.saveBanner(other.copyWith(order: b.order));
  }

  Future<void> _confirmDelete(PromoBanner b) async {
    final name = b.title.isEmpty ? 'แบนเนอร์นี้' : b.title;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบแบนเนอร์'),
        content: Text('ลบ $name ใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ลบ', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await appState.removeBanner(b.id);
      if (mounted) showSnack(context, 'ลบแบนเนอร์แล้ว');
    }
  }

  Future<void> _edit(PromoBanner? b) async {
    final isNew = b == null;
    final title = TextEditingController(text: b?.title ?? '');
    final subtitle = TextEditingController(text: b?.subtitle ?? '');
    final image = TextEditingController(text: b?.imageUrl ?? '');
    // แบนเนอร์ใหม่ให้ไปต่อท้ายเสมอ
    final nextOrder = appState.banners.isEmpty
        ? 0
        : (appState.banners.map((x) => x.order).reduce((a, c) => a > c ? a : c) + 1);
    String shopId = b?.shopId ?? '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, setSheet) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isNew ? 'เพิ่มแบนเนอร์' : 'แก้ไขแบนเนอร์',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ImageField(controller: image, label: 'รูปแบนเนอร์', kind: 'banner'),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                      hintText: 'หัวข้อ เช่น เทศกาลผักสด',
                      prefixIcon: Icon(Icons.title_rounded)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subtitle,
                  decoration: const InputDecoration(
                      hintText: 'คำอธิบายสั้น ๆ', prefixIcon: Icon(Icons.subject_rounded)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: appState.shops.any((s) => s.id == shopId) ? shopId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.storefront_outlined),
                    hintText: 'กดแล้วไปหน้าร้าน (ไม่บังคับ)',
                  ),
                  items: appState.shops
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setSheet(() => shopId = v ?? ''),
                ),
                if (shopId.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setSheet(() => shopId = ''),
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('เอาลิงก์ออก'),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      await appState.saveBanner(PromoBanner(
        id: b?.id ?? '',
        title: title.text.trim(),
        subtitle: subtitle.text.trim(),
        imageUrl: image.text.trim(),
        shopId: shopId,
        order: b?.order ?? nextOrder,
        active: b?.active ?? true,
      ));
      if (mounted) showSnack(context, isNew ? 'เพิ่มแบนเนอร์แล้ว' : 'บันทึกแบนเนอร์แล้ว');
    }

    for (final c in [title, subtitle, image]) {
      c.dispose();
    }
  }
}
