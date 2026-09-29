/// สินค้า/เมนูของร้าน (เก็บใน collection `products`)
class Product {
  final String id;
  final String shopId;
  final String name;
  final double price;
  final bool available;
  final String imageUrl; // ลิงก์รูปสินค้า (ว่าง = ใช้ไอคอนแทน)

  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.price = 0,
    this.available = true,
    this.imageUrl = '',
  });

  bool get hasImage => imageUrl.trim().isNotEmpty;

  Product copyWith({
    String? name,
    double? price,
    bool? available,
    String? imageUrl,
  }) =>
      Product(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        price: price ?? this.price,
        available: available ?? this.available,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'price': price,
        'available': available,
        'imageUrl': imageUrl,
      };

  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
        id: id,
        shopId: (m['shopId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        price: (m['price'] ?? 0).toDouble(),
        available: (m['available'] ?? true) as bool,
        imageUrl: (m['imageUrl'] ?? '') as String,
      );
}
