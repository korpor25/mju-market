import 'package:flutter/material.dart';

import '../models/stall.dart';
import '../screens/shop_detail_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// การ์ดสรุปแผงที่ผู้ซื้อแตะบนผัง + ปุ่มเข้าไปดูรายละเอียดร้าน
///
/// ใช้ทั้งในแท็บแผนที่ของผู้ซื้อและหน้าแผนที่เต็มจอที่เปิดจากหน้าร้าน
/// จึงรับแค่ [stall] แล้วไปหาร้านเองจาก [AppState.shopOfStall]
class StallInfoCard extends StatelessWidget {
  final Stall stall;
  const StallInfoCard({super.key, required this.stall});

  @override
  Widget build(BuildContext context) {
    final shop = appState.shopOfStall(stall.id);
    final title = shop?.name ?? stall.shopName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconChip(shop?.icon ?? Icons.storefront_rounded,
                color: AppColors.primary, bg: AppColors.leafSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('แผง ${stall.id}${title != null ? " · $title" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      stall.isEmpty
                          ? 'แผงว่าง · ${stall.positionLabel}'
                          : '${shop?.category ?? stall.categoryLabel} · ${stall.positionLabel}',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            StatusPill(
              stall.isEmpty
                  ? 'ว่าง'
                  : (stall.status == 'due'
                      ? 'ค้างชำระ'
                      : (stall.status == 'closed' ? 'ปิดปรับปรุง' : 'เปิดขาย')),
              tone: stall.isEmpty
                  ? 'muted'
                  : (stall.status == 'due'
                      ? 'warn'
                      : (stall.status == 'closed' ? 'bad' : 'ok')),
            ),
          ]),
          if (shop != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 15, color: AppColors.faint),
              const SizedBox(width: 6),
              // เวลาเปิด-ปิดและดาวขึ้นเฉพาะที่มีข้อมูลจริง ไม่เดาแทนร้าน
              Expanded(
                child: Text(shop.hoursLabel,
                    style: TextStyle(
                        color: shop.hasHours ? AppColors.muted : AppColors.faint,
                        fontSize: 12.5)),
              ),
              if (shop.hasRating) ...[
                Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 3),
                Text(shop.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(width: 3),
                Text('(${shop.reviews})',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ],
            ]),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
              ),
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text('ดูรายละเอียดร้าน'),
            ),
          ] else if (!stall.isEmpty) ...[
            const SizedBox(height: 10),
            // แผงมีคนเช่าอยู่แต่หาข้อมูลร้านไม่เจอ (ร้านถูกลบ หรือยังไม่ได้ผูกเลขแผง)
            Text('ยังไม่มีข้อมูลร้านของแผงนี้ในระบบ',
                style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
