/// แบนเนอร์โปรโมตบนหน้าแรกฝั่งผู้บริโภค (เก็บใน collection `banners`)
///
/// ตั้งชื่อ PromoBanner เพราะ Flutter มี widget ชื่อ Banner อยู่แล้ว ถ้าใช้ชื่อซ้ำจะชนกัน
class PromoBanner {
  final String id;
  final String title;
  final String subtitle;

  /// ลิงก์รูปพื้นหลัง (ว่าง = ใช้พื้นหลังไล่สีของแบรนด์แทน)
  final String imageUrl;

  /// กดแบนเนอร์แล้วเปิดหน้าร้านนี้ (ว่าง = ไม่ลิงก์ไปไหน)
  final String shopId;

  /// ลำดับการแสดง — น้อยมาก่อน
  final int order;

  /// ปิดชั่วคราวได้โดยไม่ต้องลบทิ้ง
  final bool active;

  const PromoBanner({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.imageUrl = '',
    this.shopId = '',
    this.order = 0,
    this.active = true,
  });

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasLink => shopId.trim().isNotEmpty;

  PromoBanner copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    String? shopId,
    int? order,
    bool? active,
  }) =>
      PromoBanner(
        id: id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        imageUrl: imageUrl ?? this.imageUrl,
        shopId: shopId ?? this.shopId,
        order: order ?? this.order,
        active: active ?? this.active,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'shopId': shopId,
        'order': order,
        'active': active,
      };

  factory PromoBanner.fromMap(String id, Map<String, dynamic> m) => PromoBanner(
        id: id,
        title: (m['title'] ?? '') as String,
        subtitle: (m['subtitle'] ?? '') as String,
        imageUrl: (m['imageUrl'] ?? '') as String,
        shopId: (m['shopId'] ?? '') as String,
        order: (m['order'] as num?)?.toInt() ?? 0,
        active: (m['active'] ?? true) as bool,
      );
}
