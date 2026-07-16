/// แผงในตลาด (สำหรับแผนผัง + จองพื้นที่)
class Stall {
  final String id; // A1, B3 ...
  final String zone; // A/B/C/D
  final String status; // occupied / empty / due / closed
  final String? shopName;
  final String pricePerDay; // เช่น 150 บาท/วัน

  const Stall({
    required this.id,
    required this.zone,
    this.status = 'empty',
    this.shopName,
    this.pricePerDay = '150 บาท/วัน',
  });

  bool get isEmpty => status == 'empty';
  bool get isBookable => status == 'empty';
}
