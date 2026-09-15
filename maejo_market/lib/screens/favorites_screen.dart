import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/shop_cards.dart';
import '../widgets/shop_ui.dart';

/// หน้ารวมร้านที่ผู้ใช้ติดตาม (รายการโปรด) — แสดงเป็นตารางแบบเดียวกับหน้าแรก
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (_, __) {
            final shops = appState.favoriteShops;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(children: [
                      CircleIconButton(Icons.arrow_back_rounded,
                          size: 42, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Expanded(child: PageHeading('ร้านที่ติดตาม')),
                    ]),
                  ),
                ),
                if (shops.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.faint),
                          const SizedBox(height: 12),
                          Text('ยังไม่มีร้านที่ติดตาม',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.muted)),
                          const SizedBox(height: 4),
                          Text('กดรูปหัวใจบนการ์ดร้านเพื่อเพิ่มร้านโปรด',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.faint)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 22,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ShopTile(shop: shops[i]),
                        childCount: shops.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
