import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/models/sale.dart';

/// สร้างรายการขายที่ย้อนหลังไป [daysAgo] วัน (เวลาเที่ยงตรง กันปัญหาเขตวัน)
Sale _sale({
  required String product,
  required double price,
  required int qty,
  int daysAgo = 0,
  String shopId = 'shop-a',
  String shopName = 'ร้าน A',
}) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day - daysAgo, 12);
  return Sale(
    id: '$product-$daysAgo-$qty',
    shopId: shopId,
    shopName: shopName,
    productId: product,
    productName: product,
    price: price,
    qty: qty,
    createdAt: d.millisecondsSinceEpoch,
  );
}

void main() {
  group('SalesStats', () {
    test('total ของแต่ละรายการ = ราคา x จำนวน', () {
      expect(_sale(product: 'ส้มตำ', price: 45, qty: 3).total, 135);
    });

    test('filter: วันนี้ / 7 วัน / 30 วัน / ทั้งหมด', () {
      final all = [
        _sale(product: 'a', price: 10, qty: 1, daysAgo: 0),
        _sale(product: 'b', price: 10, qty: 1, daysAgo: 3),
        _sale(product: 'c', price: 10, qty: 1, daysAgo: 10),
        _sale(product: 'd', price: 10, qty: 1, daysAgo: 45),
      ];
      expect(SalesStats.filter(all, SalePeriod.today).length, 1);
      expect(SalesStats.filter(all, SalePeriod.week).length, 2);
      expect(SalesStats.filter(all, SalePeriod.month).length, 3);
      expect(SalesStats.filter(all, SalePeriod.all).length, 4);
    });

    test('filter: 7 วัน รวมรายการของ 6 วันก่อน แต่ตัดของ 7 วันก่อนออก', () {
      final all = [
        _sale(product: 'in', price: 10, qty: 1, daysAgo: 6),
        _sale(product: 'out', price: 10, qty: 1, daysAgo: 7),
      ];
      final kept = SalesStats.filter(all, SalePeriod.week);
      expect(kept.map((s) => s.productName), ['in']);
    });

    test('สรุปยอด: revenue / billCount / itemCount / avgPerBill', () {
      final stats = SalesStats([
        _sale(product: 'ส้มตำ', price: 45, qty: 2), // 90
        _sale(product: 'ไก่ย่าง', price: 80, qty: 1), // 80
        _sale(product: 'ส้มตำ', price: 45, qty: 2), // 90
      ]);
      expect(stats.revenue, 260);
      expect(stats.billCount, 3);
      expect(stats.itemCount, 5);
      expect(stats.avgPerBill, closeTo(86.67, 0.01));
    });

    test('สรุปยอดของชุดว่าง ไม่หารด้วยศูนย์', () {
      const stats = SalesStats([]);
      expect(stats.revenue, 0);
      expect(stats.avgPerBill, 0);
      expect(stats.topProducts(), isEmpty);
    });

    test('daily: คืนครบทุกวันเรียงเก่า→ใหม่ และวันที่ไม่มียอดเป็น 0', () {
      final stats = SalesStats([
        _sale(product: 'a', price: 100, qty: 1, daysAgo: 0),
        _sale(product: 'b', price: 50, qty: 2, daysAgo: 2), // 100
      ]);
      final points = stats.daily(7);
      expect(points.length, 7);
      // เรียงจากเก่าไปใหม่
      expect(points.first.day.isBefore(points.last.day), isTrue);
      expect(points.last.total, 100); // วันนี้
      expect(points[points.length - 3].total, 100); // 2 วันก่อน
      expect(points[points.length - 2].total, 0); // เมื่อวาน — ไม่มียอด
    });

    test('daily: รวมยอดของวันเดียวกันเข้าด้วยกัน', () {
      final stats = SalesStats([
        _sale(product: 'a', price: 30, qty: 1),
        _sale(product: 'b', price: 70, qty: 1),
      ]);
      expect(stats.daily(7).last.total, 100);
    });

    test('topProducts: จัดอันดับตามยอดขายและรวมจำนวนชิ้น', () {
      final stats = SalesStats([
        _sale(product: 'ส้มตำ', price: 45, qty: 2), // 90
        _sale(product: 'ส้มตำ', price: 45, qty: 1), // 45  รวม 135 / 3 ชิ้น
        _sale(product: 'ไก่ย่าง', price: 80, qty: 1), // 80
      ]);
      final top = stats.topProducts();
      expect(top.first.label, 'ส้มตำ');
      expect(top.first.total, 135);
      expect(top.first.qty, 3);
      expect(top[1].label, 'ไก่ย่าง');
    });

    test('topShops + shopCount: แยกยอดรายร้านสำหรับรายงานแอดมิน', () {
      final stats = SalesStats([
        _sale(product: 'a', price: 100, qty: 1, shopId: 's1', shopName: 'ร้านหนึ่ง'),
        _sale(product: 'b', price: 300, qty: 1, shopId: 's2', shopName: 'ร้านสอง'),
        _sale(product: 'c', price: 50, qty: 1, shopId: 's1', shopName: 'ร้านหนึ่ง'),
      ]);
      expect(stats.shopCount, 2);
      final top = stats.topShops();
      expect(top.first.label, 'ร้านสอง');
      expect(top.first.total, 300);
      expect(top[1].total, 150);
    });
  });

  group('Sale.fromMap', () {
    test('อ่าน createdAt ที่เป็น millis ได้', () {
      final s = Sale.fromMap('id1', {
        'shopId': 's1',
        'productName': 'ส้มตำ',
        'price': 45,
        'qty': 2,
        'createdAt': 1700000000000,
      });
      expect(s.total, 90);
      expect(s.createdAt, 1700000000000);
    });

    test('createdAt เป็น null (serverTimestamp ยังไม่ resolve) ไม่ทำให้พัง', () {
      final s = Sale.fromMap('id2', {'shopId': 's1', 'productName': 'x'});
      expect(s.createdAt, 0);
      expect(s.qty, 1);
    });
  });
}
