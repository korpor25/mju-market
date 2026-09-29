import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop.dart';

/// ร้านหนึ่งรายการในประวัติการเข้าชม
///
/// เก็บรายละเอียดร้านซ้ำไว้ด้วย (ไม่ใช่แค่ id) เพราะร้านอาจถูกลบหรือเปลี่ยนชื่อ
/// ประวัติต้องยังอ่านออกว่าเคยเข้าดูอะไรไว้
class VisitedShop {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String stallId;
  final String zone;

  /// เวลาที่เข้าดูล่าสุด (millisecondsSinceEpoch)
  final int at;

  const VisitedShop({
    required this.id,
    required this.name,
    this.category = '',
    this.imageUrl = '',
    this.stallId = '',
    this.zone = '',
    this.at = 0,
  });

  String get whereLabel {
    if (stallId.isEmpty) return category.isEmpty ? 'ยังไม่จองแผง' : category;
    final place = zone.isEmpty ? 'แผง $stallId' : 'โซน $zone · แผง $stallId';
    return category.isEmpty ? place : '$place · $category';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'imageUrl': imageUrl,
        'stallId': stallId,
        'zone': zone,
        'at': at,
      };

  factory VisitedShop.fromMap(Map<String, dynamic> m) => VisitedShop(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        category: (m['category'] ?? '') as String,
        imageUrl: (m['imageUrl'] ?? '') as String,
        stallId: (m['stallId'] ?? '') as String,
        zone: (m['zone'] ?? '') as String,
        at: (m['at'] as num?)?.toInt() ?? 0,
      );
}

/// ประวัติการเข้าชมร้าน — เก็บในเครื่องผู้ใช้เท่านั้น
///
/// ตั้งใจไม่เก็บลง Firestore: ไม่มีใครอื่นต้องใช้ข้อมูลนี้ และการเก็บในเครื่อง
/// ทำให้ผู้เยี่ยมชมที่ยังไม่ลงทะเบียนมีประวัติของตัวเองได้เหมือนกัน
class VisitHistory {
  VisitHistory._();

  static const _key = 'visitHistory';

  /// เก็บย้อนหลังแค่นี้พอ — ประวัติที่ยาวกว่านี้ไม่มีใครเลื่อนดู
  static const int maxItems = 30;

  static Future<List<VisitedShop>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const [];
      return raw
          .map((s) => VisitedShop.fromMap(jsonDecode(s) as Map<String, dynamic>))
          .where((v) => v.id.isNotEmpty)
          .toList();
    } catch (e) {
      // อ่านไม่ได้ (ข้อมูลเก่าคนละรูปแบบ/เบราว์เซอร์ปิด storage) = ถือว่ายังไม่มีประวัติ
      debugPrint('visit history load failed: $e');
      return [];
    }
  }

  /// บันทึกว่าเพิ่งเข้าดูร้านนี้ — ร้านเดิมถูกเลื่อนขึ้นบนสุดแทนการเพิ่มซ้ำ
  static Future<void> record(Shop shop) async {
    if (shop.id.isEmpty) return;
    try {
      final list = await load();
      list.removeWhere((v) => v.id == shop.id);
      list.insert(
        0,
        VisitedShop(
          id: shop.id,
          name: shop.name,
          category: shop.category,
          imageUrl: shop.imageUrl,
          stallId: shop.stallId,
          zone: shop.zone,
          at: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        list.take(maxItems).map((v) => jsonEncode(v.toMap())).toList(),
      );
    } catch (e) {
      // บันทึกประวัติไม่สำเร็จต้องไม่ทำให้การเปิดหน้าร้านพัง
      debugPrint('visit history record failed: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('visit history clear failed: $e');
    }
  }
}
