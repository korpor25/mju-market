/// รายการขาย 1 บรรทัด (เก็บใน collection `sales`)
///
/// ผู้ขายเป็นคนบันทึกเอง — เลือกสินค้า + จำนวน แล้วระบบเก็บราคา ณ เวลาที่ขาย
/// (`price`) ไว้ด้วย เพื่อให้ยอดย้อนหลังไม่เปลี่ยนตามการแก้ราคาสินค้าภายหลัง
class Sale {
  final String id;
  final String shopId;
  final String shopName; // เก็บซ้ำไว้ให้แอดมินสรุปได้โดยไม่ต้องอ่าน shops
  final String productId;
  final String productName;
  final double price; // ราคาต่อหน่วย ณ เวลาที่ขาย
  final int qty;
  final String note;
  final int createdAt; // millisSinceEpoch

  const Sale({
    required this.id,
    required this.shopId,
    this.shopName = '',
    this.productId = '',
    required this.productName,
    this.price = 0,
    this.qty = 1,
    this.note = '',
    this.createdAt = 0,
  });

  double get total => price * qty;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(createdAt);

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'shopName': shopName,
        'productId': productId,
        'productName': productName,
        'price': price,
        'qty': qty,
        'note': note,
      };

  factory Sale.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    int millis = 0;
    // Firestore Timestamp -> millis (ปลอดภัยแม้ยังเป็น null ระหว่าง serverTimestamp)
    if (ts is int) {
      millis = ts;
    } else if (ts != null) {
      try {
        millis = ts.millisecondsSinceEpoch as int;
      } catch (_) {
        try {
          millis = ts.toDate().millisecondsSinceEpoch as int;
        } catch (_) {}
      }
    }
    return Sale(
      id: id,
      shopId: (m['shopId'] ?? '') as String,
      shopName: (m['shopName'] ?? '') as String,
      productId: (m['productId'] ?? '') as String,
      productName: (m['productName'] ?? '') as String,
      price: ((m['price'] ?? 0) as num).toDouble(),
      qty: ((m['qty'] ?? 1) as num).toInt(),
      note: (m['note'] ?? '') as String,
      createdAt: millis,
    );
  }
}

/// ช่วงเวลาของรายงาน
enum SalePeriod { today, week, month, all }

extension SalePeriodX on SalePeriod {
  String get labelTh {
    switch (this) {
      case SalePeriod.today:
        return 'วันนี้';
      case SalePeriod.week:
        return '7 วัน';
      case SalePeriod.month:
        return '30 วัน';
      case SalePeriod.all:
        return 'ทั้งหมด';
    }
  }

  /// จำนวนวันที่ย้อนหลัง (นับวันนี้เป็น 1) — `all` = 0 คือไม่จำกัด
  int get days {
    switch (this) {
      case SalePeriod.today:
        return 1;
      case SalePeriod.week:
        return 7;
      case SalePeriod.month:
        return 30;
      case SalePeriod.all:
        return 0;
    }
  }

  /// จำนวนแท่งที่เหมาะกับกราฟรายวันของช่วงนี้
  int get chartDays => this == SalePeriod.all ? 30 : (this == SalePeriod.today ? 7 : days);
}

/// ยอดขายรายวัน 1 จุดบนกราฟ
class DailyPoint {
  final DateTime day;
  final double total;
  const DailyPoint(this.day, this.total);
}

/// 1 แถวของตารางจัดอันดับ (สินค้าขายดี / ร้านขายดี)
class RankRow {
  final String id;
  final String label;
  final double total;
  final int qty;
  const RankRow({required this.id, required this.label, required this.total, required this.qty});
}

/// สรุปสถิติจากรายการขายที่กรองช่วงเวลาแล้ว
class SalesStats {
  final List<Sale> sales;
  const SalesStats(this.sales);

  /// กรองรายการขายตามช่วงเวลา (นับตั้งแต่เที่ยงคืนของวันเริ่มช่วง)
  static List<Sale> filter(List<Sale> all, SalePeriod period) {
    if (period == SalePeriod.all) return all;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - (period.days - 1));
    final ms = from.millisecondsSinceEpoch;
    return all.where((s) => s.createdAt >= ms).toList();
  }

  double get revenue => sales.fold(0.0, (sum, s) => sum + s.total);
  int get billCount => sales.length;
  int get itemCount => sales.fold(0, (sum, s) => sum + s.qty);
  double get avgPerBill => billCount == 0 ? 0 : revenue / billCount;
  int get shopCount => sales.map((s) => s.shopId).toSet().length;

  /// ยอดขายรายวันย้อนหลัง [days] วัน (เรียงเก่า → ใหม่, วันที่ไม่มียอด = 0)
  List<DailyPoint> daily(int days) {
    final byDay = <int, double>{};
    for (final s in sales) {
      final k = _dayKey(s.date);
      byDay[k] = (byDay[k] ?? 0) + s.total;
    }
    final now = DateTime.now();
    final out = <DailyPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      out.add(DailyPoint(d, byDay[_dayKey(d)] ?? 0));
    }
    return out;
  }

  /// สินค้าขายดี เรียงตามยอดขายรวม
  List<RankRow> topProducts({int limit = 5}) =>
      _rank(limit, (s) => s.productId.isEmpty ? s.productName : s.productId, (s) => s.productName);

  /// ร้านขายดี เรียงตามยอดขายรวม
  List<RankRow> topShops({int limit = 10}) =>
      _rank(limit, (s) => s.shopId, (s) => s.shopName.isEmpty ? s.shopId : s.shopName);

  List<RankRow> _rank(int limit, String Function(Sale) keyOf, String Function(Sale) labelOf) {
    final totals = <String, double>{};
    final qtys = <String, int>{};
    final labels = <String, String>{};
    for (final s in sales) {
      final k = keyOf(s);
      totals[k] = (totals[k] ?? 0) + s.total;
      qtys[k] = (qtys[k] ?? 0) + s.qty;
      labels[k] = labelOf(s);
    }
    final rows = totals.keys
        .map((k) => RankRow(id: k, label: labels[k] ?? k, total: totals[k]!, qty: qtys[k] ?? 0))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return rows.take(limit).toList();
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

const _thMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// วันที่แบบสั้น เช่น "5 ส.ค."
String thaiShortDate(DateTime d) => '${d.day} ${_thMonths[d.month - 1]}';

/// วันที่ + เวลา เช่น "5 ส.ค. 14:30"
String thaiDateTime(DateTime d) =>
    '${thaiShortDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
