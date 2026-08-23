import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'buyer/buyer_shell.dart' show ShopRow;

/// หน้ารวมร้านที่ผู้ใช้ติดตาม (รายการโปรด)
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร้านที่ติดตาม')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          final shops = appState.favoriteShops;
          if (shops.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.faint),
                    const SizedBox(height: 12),
                    Text('ยังไม่มีร้านที่ติดตาม',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text('กดรูปหัวใจในหน้าร้านเพื่อเพิ่มร้านโปรด',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.faint)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => ShopRow(shop: shops[i]),
          );
        },
      ),
    );
  }
}
