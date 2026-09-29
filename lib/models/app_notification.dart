/// การแจ้งเตือนในแอป (collection `notifications`)
class AppNotification {
  final String id;
  final String uid; // เจ้าของการแจ้งเตือน
  final String title;
  final String body;
  final bool read;
  final int createdAt; // millisSinceEpoch (สำหรับเรียงลำดับ)

  const AppNotification({
    required this.id,
    required this.uid,
    required this.title,
    this.body = '',
    this.read = false,
    this.createdAt = 0,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
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
    return AppNotification(
      id: id,
      uid: (m['uid'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      read: (m['read'] ?? false) as bool,
      createdAt: millis,
    );
  }
}
