import 'package:flutter/material.dart';

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
  final String ownerUid; // uid ของเจ้าของร้าน (เชื่อมกับ users)
  final String description; // รายละเอียดร้าน
  final String hours; // เวลาเปิด-ปิด เช่น "06.00 - 14.00 น."
  final String imageUrl; // ลิงก์รูปร้าน (ว่าง = ใช้ไอคอนแทน)

  /// วันที่แอดมินยืนยันรับชำระล่าสุด (null = ยังไม่เคยจ่าย)
  /// ใช้คำนวณว่ารอบเดือนนี้ค้างหรือยัง แทนการเก็บสถานะค้างไว้เฉย ๆ
  final DateTime? lastPaidAt;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerName,
    required this.stallId,
    required this.zone,
    this.status = 'open',
    this.payStatus = 'ok',
    this.rating = 0,
    this.reviews = 0,
    this.ownerUid = '',
    this.description = '',
    this.hours = '',
    this.imageUrl = '',
    this.lastPaidAt,
  });

  bool get hasImage => imageUrl.trim().isNotEmpty;

  /// ร้านนี้มีคะแนนจากรีวิวจริงแล้วหรือยัง
  bool get hasRating => reviews > 0 && rating > 0;

  /// เจ้าของร้านกรอกเวลาเปิด-ปิดไว้หรือยัง (ว่าง = ต้องไม่เดาเวลาให้)
  bool get hasHours => hours.trim().isNotEmpty;
  String get hoursLabel => hasHours ? 'เปิด $hours' : 'ยังไม่ระบุเวลาเปิด-ปิด';

  /// ยังไม่ได้จัดสรรแผง (ผู้ขายเพิ่งได้รับอนุมัติ แต่ยังไม่ได้จองแผง)
  bool get hasStall => stallId.isNotEmpty;
  String get stallLabel => hasStall ? stallId : 'ยังไม่จองแผง';
  String get zoneLabel => zone.isNotEmpty ? 'โซน $zone · $category' : category;

  /// ไอคอนประจำร้าน — เลือกตามหมวดหมู่ (แทน emoji เดิม)
  IconData get icon {
    switch (category) {
      case 'อาหาร':
        return Icons.ramen_dining_rounded;
      case 'ผักสด':
      case 'ผลไม้':
      case 'ผัก / ผลไม้':
        return Icons.eco_rounded;
      case 'เครื่องดื่ม':
        return Icons.local_cafe_rounded;
      case 'ประมง':
        return Icons.set_meal_rounded;
      case 'ของแห้ง':
        return Icons.inventory_2_rounded;
      case 'ของใช้':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

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
        'ownerUid': ownerUid,
        'description': description,
        'hours': hours,
        'imageUrl': imageUrl,
        'lastPaidAt': lastPaidAt?.millisecondsSinceEpoch,
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
        // ไม่มีฟิลด์ rating = ยังไม่เคยมีใครรีวิว ต้องเป็น 0 ไม่ใช่ค่าเดา
        rating: (m['rating'] ?? 0).toDouble(),
        reviews: (m['reviews'] ?? 0) as int,
        ownerUid: (m['ownerUid'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        hours: (m['hours'] ?? '') as String,
        imageUrl: (m['imageUrl'] ?? '') as String,
        lastPaidAt: _toDate(m['lastPaidAt']),
      );

  /// รองรับทั้ง millis ที่แอปเขียน และ Timestamp ถ้ามีใครเขียนมาจากที่อื่น
  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try {
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
