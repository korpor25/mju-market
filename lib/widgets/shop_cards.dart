import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/shop.dart';
import '../screens/shop_detail_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'common.dart';
import 'shop_ui.dart';

/// การ์ดร้านแบบตาราง (รูปใหญ่ + หัวใจ + คะแนน) — ใช้ทั้งหน้าแรก ค้นหา และร้านโปรด
class ShopTile extends StatelessWidget {
  final Shop shop;

  /// ปิดปุ่มหัวใจในบางที่ (เช่นในหน้าร้านโปรดที่ทุกใบถูกติดตามอยู่แล้ว ก็ยังโชว์ได้)
  final bool showFavorite;

  const ShopTile({super.key, required this.shop, this.showFavorite = true});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final canFav = showFavorite && appState.isLoggedIn;
        return TileCard(
          imageUrl: shop.imageUrl,
          fallbackIcon: shop.icon,
          title: shop.name,
          subtitle: shop.hasStall ? 'โซน ${shop.zone} · ${shop.category}' : shop.category,
          rating: shop.rating,
          reviewCount: shop.reviews,
          trailingText: shop.stallLabel,
          trailingColor: shop.hasStall ? AppColors.primary : AppColors.muted,
          favorite: canFav ? appState.isFavorite(shop.id) : null,
          onFavorite: () => appState.toggleFavorite(shop.id),
          badge: shop.status == 'closed' ? StatusPill('ปิดปรับปรุง', tone: 'bad') : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
          ),
        );
      },
    );
  }
}

/// การ์ดสินค้า/เมนูแบบตาราง (ในหน้าร้าน)
class ProductTile extends StatelessWidget {
  final Product product;
  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return TileCard(
      imageUrl: product.imageUrl,
      fallbackIcon: Icons.restaurant_rounded,
      title: product.name,
      trailingText: '฿${product.price.toStringAsFixed(0)}',
      trailingColor: AppColors.text,
      badge: product.available ? null : StatusPill('หมด', tone: 'bad'),
    );
  }
}

/// แถวร้านแบบกะทัดรัด (ใช้ในรายการแนวตั้งที่ต้องการความหนาแน่นสูง)
class ShopRow extends StatelessWidget {
  final Shop shop;
  const ShopRow({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(kTileRadius),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 60,
              height: 60,
              child: CoverImage(
                  url: shop.imageUrl, fallback: shop.icon, bg: AppColors.surface2, iconSize: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(shop.hasStall ? 'แผง ${shop.stallId} · ${shop.category}' : shop.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 4),
                RatingLine(rating: shop.rating, count: shop.reviews, size: 12.5),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ]),
      ),
    );
  }
}
