import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ประเภทคำขอที่ผู้ดูแลระบบต้องอนุมัติ
enum RequestType { sellerApply, booking, payment, move, close }

extension RequestTypeX on RequestType {
  String get id => name;

  String get labelTh {
    switch (this) {
      case RequestType.sellerApply:
        return 'คำขอเปิดร้าน/สมัครผู้ขาย';
      case RequestType.booking:
        return 'คำขอจองพื้นที่ขาย';
      case RequestType.payment:
        return 'ยืนยันรับชำระค่าเช่า';
      case RequestType.move:
        return 'คำขอย้ายแผง';
      case RequestType.close:
        return 'คำขอปิดร้านชั่วคราว';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestType.sellerApply:
        return Icons.storefront_outlined;
      case RequestType.booking:
        return Icons.grid_view_rounded;
      case RequestType.payment:
        return Icons.payments_outlined;
      case RequestType.move:
        return Icons.swap_horiz_rounded;
      case RequestType.close:
        return Icons.pause_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case RequestType.sellerApply:
        return AppColors.primary;
      case RequestType.booking:
        return AppColors.primaryLight;
      case RequestType.payment:
        return AppColors.accent;
      case RequestType.move:
        return AppColors.muted;
      case RequestType.close:
        return AppColors.bad;
    }
  }

  static RequestType fromId(String? v) {
    return RequestType.values.firstWhere(
      (e) => e.id == v,
      orElse: () => RequestType.sellerApply,
    );
  }
}

class MarketRequest {
  final String id;
  final RequestType type;
  final String title; // ชื่อร้าน / หัวข้อ
  final String subtitle; // รายละเอียด
  final String amount; // ฿1,500/เดือน หรือ "—"
  final String requesterName;
  final String status; // pending / approved / rejected

  /// uid ของผู้ยื่นคำขอ — ใช้เช็คว่าเป็นคำขอของตัวเองไหม
  /// (เจ้าของตลาดที่ขายเองด้วยจะได้เห็นสถานะคำขอของตัวเอง)
  final String uid;

  /// ร้านที่เกี่ยวข้องกับคำขอ (คำขอจองแผงจะระบุว่าร้านไหนขอจอง)
  /// เดิมยัดรหัสร้านไว้ในช่อง uid ได้เพราะ 1 คน 1 ร้าน ตอนนี้ต้องแยกกัน
  final String shopId;

  /// สลิปโอนเงินที่ผู้ขายแนบมา (เฉพาะคำขอชนิดชำระเงิน)
  final String slipUrl;

  const MarketRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.amount = '—',
    this.requesterName = '',
    this.status = 'pending',
    this.uid = '',
    this.shopId = '',
    this.slipUrl = '',
  });

  bool get isPayment => type == RequestType.payment;

  Map<String, dynamic> toMap() => {
        'type': type.id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'requesterName': requesterName,
        'status': status,
        'uid': uid,
        'shopId': shopId,
        'slipUrl': slipUrl,
      };

  factory MarketRequest.fromMap(String id, Map<String, dynamic> m) => MarketRequest(
        id: id,
        type: RequestTypeX.fromId(m['type'] as String?),
        title: (m['title'] ?? '') as String,
        subtitle: (m['subtitle'] ?? '') as String,
        amount: (m['amount'] ?? '—') as String,
        requesterName: (m['requesterName'] ?? '') as String,
        status: (m['status'] ?? 'pending') as String,
        uid: (m['uid'] ?? '') as String,
        shopId: (m['shopId'] ?? '') as String,
        slipUrl: (m['slipUrl'] ?? '') as String,
      );
}
