import 'package:flutter/material.dart';

import '../models/promo_banner.dart';
import '../screens/shop_detail_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// แบนเนอร์หน้าแรก — แอดมินจัดการเนื้อหาเอง (collection `banners`)
/// ถ้ายังไม่มีแบนเนอร์เลย จะแสดงพื้นหลังไล่สีของแบรนด์ไว้ก่อน หน้าแรกจะได้ไม่โหว่
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => BannerCarouselState();
}

class BannerCarouselState extends State<BannerCarousel> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _open(PromoBanner b) {
    if (!b.hasLink) return;
    final shop = appState.shops.where((s) => s.id == b.shopId).firstOrNull;
    if (shop == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)));
  }

  @override
  Widget build(BuildContext context) {
    final items = appState.activeBanners;
    final list = items.isEmpty
        ? const [PromoBanner(id: '', title: 'ตลาดแม่โจ้', subtitle: 'ของสดของดีจากชุมชน')]
        : items;

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _page,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: i == list.length - 1 ? 0 : 10),
              child: _BannerCard(banner: list[i], onTap: () => _open(list[i])),
            ),
          ),
        ),
        if (list.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < list.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final VoidCallback onTap;
  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: banner.hasLink ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.hasImage)
              Image.network(banner.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: brandGradient)))
            else
              DecoratedBox(decoration: BoxDecoration(gradient: brandGradient)),
            // ไล่เฉดดำบาง ๆ ให้ตัวหนังสืออ่านออกไม่ว่ารูปจะสว่างแค่ไหน
            if (banner.hasImage)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xCC000000), Color(0x33000000)],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (banner.title.isNotEmpty)
                    Text(banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (banner.subtitle.isNotEmpty)
                    Text(banner.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  if (banner.hasLink) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('ดูเพิ่มเติม',
                          style: TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
