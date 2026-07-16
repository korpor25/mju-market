import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class ShopDetailScreen extends StatelessWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final menu = [
      ('ข้าวซอยไก่', '60 บาท'),
      ('น้ำพริกหนุ่ม', '35 บาท'),
      ('ไส้อั่ว', '40 บาท'),
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.primary,
            actions: const [Icon(Icons.favorite_border_rounded), SizedBox(width: 12)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: brandGradient),
                child: Center(child: Text(shop.emoji, style: const TextStyle(fontSize: 76))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(shop.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    const StatusPill('ร้านแนะนำ', tone: 'ok'),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 4),
                    Text('${shop.rating}  (${shop.reviews} รีวิว)',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  _infoRow(Icons.access_time_rounded, 'เปิด 06.00 - 14.00 น.'),
                  _infoRow(Icons.place_outlined, 'โซน ${shop.zone} · แผง ${shop.stallId}'),
                  _infoRow(Icons.sell_outlined, 'หมวด: ${shop.category}'),
                  const SectionTitle('เมนูแนะนำ', icon: Icons.restaurant_menu_rounded),
                  ...menu.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.ramen_dining_outlined, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m.$1, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text(m.$2, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ]),
                        ),
                      )),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('ดูแผนที่'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => showSnack(context, 'ติดตามร้าน ${shop.name} แล้ว'),
                        icon: const Icon(Icons.add),
                        label: const Text('ติดตามร้าน'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      );
}
