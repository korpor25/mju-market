/// รีวิวร้านค้าจากลูกค้า (เก็บใน collection `reviews`)
///
/// doc id = `${shopId}_${uid}` → 1 รีวิวต่อผู้ใช้ต่อร้าน (เขียนซ้ำ = แก้ของเดิม)
class Review {
  final String id;
  final String shopId;
  final String uid; // ผู้เขียนรีวิว
  final String authorName;
  final int rating; // 1..5 ดาว
  final String comment;
  final int createdAt; // millisSinceEpoch (สำหรับเรียงลำดับ)

  const Review({
    required this.id,
    required this.shopId,
    required this.uid,
    required this.authorName,
    this.rating = 5,
    this.comment = '',
    this.createdAt = 0,
  });

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'uid': uid,
        'authorName': authorName,
        'rating': rating,
        'comment': comment,
      };

  factory Review.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    int millis = 0;
    // Firestore Timestamp -> millis (ปลอดภัยแม้ยังเป็น null ระหว่าง serverTimestamp)
    if (ts != null && ts is! int) {
      try {
        millis = (ts.millisecondsSinceEpoch as int);
      } catch (_) {
        try {
          millis = ts.toDate().millisecondsSinceEpoch as int;
        } catch (_) {}
      }
    } else if (ts is int) {
      millis = ts;
    }
    return Review(
      id: id,
      shopId: (m['shopId'] ?? '') as String,
      uid: (m['uid'] ?? '') as String,
      authorName: (m['authorName'] ?? '') as String,
      rating: ((m['rating'] ?? 5) as num).toInt(),
      comment: (m['comment'] ?? '') as String,
      createdAt: millis,
    );
  }
}
