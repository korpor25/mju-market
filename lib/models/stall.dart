/// แผงในตลาด (สำหรับแผนผัง + จองพื้นที่)
class Stall {
  final String id; // A-1, B-3 ...
  final String zone; // A/B/C/D
  final String status; // occupied / empty / due / closed
  final String? shopName;

  /// หมวดสินค้าประจำแผง — ใช้ค่าชุดเดียวกับ shopCategories
  /// ค่าว่าง = ยังไม่กำหนดหมวด
  final String category;

  /// ค่าเช่าต่อวัน (บาท) — แต่ละแผงตั้งไม่เท่ากันได้
  final int pricePerDay;

  const Stall({
    required this.id,
    required this.zone,
    this.status = 'empty',
    this.shopName,
    this.category = '',
    this.pricePerDay = 150,
  });

  bool get isEmpty => status == 'empty';
  bool get isBookable => status == 'empty';

  /// ลำดับแผงภายในโซน เช่น 'A-12' -> 12
  int get number => int.tryParse(id.split('-').last) ?? 0;

  String get categoryLabel => category.isEmpty ? 'ไม่ระบุหมวด' : category;

  /// ตำแหน่งแบบอ่านง่าย เช่น 'โซน A · แผงที่ 12'
  String get positionLabel => 'โซน $zone · แผงที่ $number';

  Stall copyWith({
    String? status,
    String? shopName,
    String? category,
    int? pricePerDay,
  }) =>
      Stall(
        id: id,
        zone: zone,
        status: status ?? this.status,
        shopName: shopName ?? this.shopName,
        category: category ?? this.category,
        pricePerDay: pricePerDay ?? this.pricePerDay,
      );

  Map<String, dynamic> toMap() => {
        'zone': zone,
        'status': status,
        'shopName': shopName,
        'category': category,
        'pricePerDay': pricePerDay,
      };

  /// รองรับเอกสารเก่าที่ยังไม่มี category / pricePerDay
  /// และเอกสารที่เคยเก็บราคาเป็นข้อความ เช่น '150 บาท/วัน'
  factory Stall.fromMap(String id, Map<String, dynamic> m) => Stall(
        id: id,
        zone: (m['zone'] ?? id.split('-').first) as String,
        status: (m['status'] ?? 'empty') as String,
        shopName: m['shopName'] as String?,
        category: (m['category'] ?? '') as String,
        pricePerDay: parsePrice(m['pricePerDay']),
      );

  static int parsePrice(Object? v) {
    if (v is num) return v.toInt();
    if (v is String) {
      final digits = RegExp(r'\d+').firstMatch(v)?.group(0);
      if (digits != null) return int.tryParse(digits) ?? 150;
    }
    return 150;
  }
}
