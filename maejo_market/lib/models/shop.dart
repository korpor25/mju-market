class Shop {
  final String id;
  final String name;
  final String category; // ผักสด, ผลไม้, อาหาร, ประมง, ของแห้ง ฯลฯ
  final String ownerName;
  final String stallId; // เลขแผง เช่น A-14
  final String zone; // A/B/C/D
  final String status; // open / closed / pending
  final String payStatus; // ok / due / bad
  final double rating;
  final int reviews;
  final String emoji;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerName,
    required this.stallId,
    required this.zone,
    this.status = 'open',
    this.payStatus = 'ok',
    this.rating = 4.5,
    this.reviews = 0,
    this.emoji = '🥬',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'ownerName': ownerName,
        'stallId': stallId,
        'zone': zone,
        'status': status,
        'payStatus': payStatus,
        'rating': rating,
        'reviews': reviews,
        'emoji': emoji,
      };

  factory Shop.fromMap(String id, Map<String, dynamic> m) => Shop(
        id: id,
        name: (m['name'] ?? '') as String,
        category: (m['category'] ?? '') as String,
        ownerName: (m['ownerName'] ?? '') as String,
        stallId: (m['stallId'] ?? '') as String,
        zone: (m['zone'] ?? '') as String,
        status: (m['status'] ?? 'open') as String,
        payStatus: (m['payStatus'] ?? 'ok') as String,
        rating: (m['rating'] ?? 4.5).toDouble(),
        reviews: (m['reviews'] ?? 0) as int,
        emoji: (m['emoji'] ?? '🥬') as String,
      );
}
