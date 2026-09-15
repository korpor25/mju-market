import 'package:flutter/material.dart';

/// ========================================================================
/// ผังตลาดแม่โจ้ (ตามแบบร่างที่ตลาดให้มา)
///
/// เก็บ "ตำแหน่งจริง" ของแต่ละแผงไว้ในโค้ด เพราะผังกายภาพไม่ได้เปลี่ยนบ่อย
/// ส่วนสถานะ/ราคา/ชื่อร้าน ยังมาจาก Firestore เหมือนเดิม (model [Stall])
///
/// พิกัดอยู่ในระบบของผังเอง (0,0 = มุมซ้ายบน ถึง 920 x 1050)
/// ตอนวาดจะย่อ/ขยายให้พอดีความกว้างที่มี จึงไม่ต้องแปลงหน่วยเอง
/// ========================================================================

/// ย่านหนึ่งในตลาด — แยกด้วยสีให้เห็นชัดว่าเดินไปทางไหนเจออะไร
class MarketSection {
  final String id;
  final String label;
  final Color color;
  final IconData icon;

  /// ค่าเช่าต่อวันที่แนะนำ (ใช้ตอนสร้างแผงตามผัง)
  final int pricePerDay;

  const MarketSection({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
    this.pricePerDay = 150,
  });
}

/// ช่องแผงหนึ่งช่องบนผัง
class StallSlot {
  final String id;
  final String sectionId;
  final double x, y, w, h;
  const StallSlot(this.id, this.sectionId, this.x, this.y, this.w, this.h);

  bool get isTall => h > w * 1.6;
  Offset get center => Offset(x + w / 2, y + h / 2);
}

/// ด้านที่ทางเข้าอยู่ (ใช้เลือกทิศของลูกศร)
enum GateSide { top, bottom, left, right }

/// ทางเข้าตลาด (ลูกศรชี้ออกด้านที่เดินเข้ามา)
class MarketGate {
  final double x, y;
  final GateSide side;
  const MarketGate(this.x, this.y, {this.side = GateSide.top});

  bool get isVertical => side == GateSide.top || side == GateSide.bottom;
}

class MarketLayout {
  MarketLayout._();

  /// ผังต้นฉบับวาดเป็นแนวตั้ง (สูงกว่ากว้าง) แต่บนจอมือถือแผงยาว ๆ ของโซนผัก
  /// จะกลายเป็นเส้นผอมอ่านไม่ออก จึงหมุนผัง 90° ทวนเข็มก่อนแสดงผล
  /// (ทิศบนของผังต้นฉบับ = ด้านซ้ายของจอ)
  static const bool rotated = true;

  static const Size _rawSize = Size(920, 1080);

  /// แถวผักยาวหนึ่งแถวแบ่งเป็นกี่ล็อค
  static const int _vegLotsPerRow = 5;

  /// ขนาดของผังหลังหมุนแล้ว
  static Size get size =>
      rotated ? Size(_rawSize.height, _rawSize.width) : _rawSize;

  static const List<MarketSection> sections = [
    MarketSection(
      id: 'fresh',
      label: 'ของสด',
      color: Color(0xFF2E7D32),
      icon: Icons.set_meal_rounded,
      pricePerDay: 200,
    ),
    MarketSection(
      id: 'veg',
      label: 'ผัก',
      color: Color(0xFF7CB342),
      icon: Icons.eco_rounded,
      pricePerDay: 150,
    ),
    MarketSection(
      id: 'sew',
      label: 'ร้านเย็บเสื้อ',
      color: Color(0xFF5C6BC0),
      icon: Icons.checkroom_rounded,
      pricePerDay: 160,
    ),
    MarketSection(
      id: 'cooked',
      label: 'กับข้าวสุก',
      color: Color(0xFFEF6C00),
      icon: Icons.rice_bowl_rounded,
      pricePerDay: 220,
    ),
    MarketSection(
      id: 'restaurant',
      label: 'ร้านอาหาร',
      color: Color(0xFFD84315),
      icon: Icons.ramen_dining_rounded,
      pricePerDay: 240,
    ),
    MarketSection(
      id: 'grill',
      label: 'ปิ้งไก่',
      color: Color(0xFF8D6E63),
      icon: Icons.outdoor_grill_rounded,
      pricePerDay: 210,
    ),
    MarketSection(
      id: 'forest',
      label: 'ของป่า',
      color: Color(0xFF00897B),
      icon: Icons.forest_rounded,
      pricePerDay: 140,
    ),
    MarketSection(
      id: 'fruit',
      label: 'ผลไม้',
      color: Color(0xFFF9A825),
      icon: Icons.apple_rounded,
      pricePerDay: 170,
    ),
    MarketSection(
      id: 'flower',
      label: 'ดอกไม้',
      color: Color(0xFFD81B60),
      icon: Icons.local_florist_rounded,
      pricePerDay: 150,
    ),
  ];

  /// โซน A — "ของสด" ล้อมเป็นวงรอบลานกลาง (ไล่ตามเข็มนาฬิกาจากซ้ายบน)
  /// โซน B — "ผัก" แผงยาว 6 แถว แถวละ 5 ล็อค (B-1..B-30) มีทางเดินคั่นกลาง
  /// โซน C — อาคารยาว 3 แถว แบ่งตามประเภทร้าน 4 ช่วง (ซ้าย→ขวา)
  /// โซน D — แถวล่างสุด 4 ช่วง คั่นด้วยทางเข้า 3 จุด
  static final List<StallSlot> _rawSlots = [
    // ---- A: ของสด ----
    StallSlot('A-1', 'fresh', 225, 18, 20, 64),
    StallSlot('A-2', 'fresh', 273, 22, 70, 36),
    StallSlot('A-3', 'fresh', 365, 21, 67, 36),
    StallSlot('A-4', 'fresh', 455, 24, 67, 38),
    StallSlot('A-5', 'fresh', 548, 18, 58, 36),
    StallSlot('A-6', 'fresh', 620, 30, 28, 60),
    StallSlot('A-7', 'fresh', 618, 94, 30, 64),
    StallSlot('A-8', 'fresh', 580, 176, 76, 34),
    StallSlot('A-9', 'fresh', 478, 178, 76, 32),
    StallSlot('A-10', 'fresh', 314, 178, 78, 34),
    StallSlot('A-11', 'fresh', 218, 178, 74, 32),
    StallSlot('A-12', 'fresh', 220, 98, 28, 62),

    // ---- B: ผัก — แถวยาว 6 แถว แบ่งแถวละ 5 ล็อคเท่า ๆ กัน ----
    // พิกัดดิบแถวหนึ่งยาวจาก y=240 ถึง 628 (หลังหมุนผังกลายเป็นแนวนอน ปลาย y มากอยู่ซ้ายจอ)
    // จึงไล่ล็อคจาก y มากไปน้อย ให้เลขเรียงซ้าย→ขวาบนจอ และเรียงแถวบน→ล่าง
    for (final (row, x) in const [188.0, 263.0, 342.0, 488.0, 580.0, 658.0].indexed)
      for (var lot = 0; lot < _vegLotsPerRow; lot++)
        StallSlot(
          'B-${row * _vegLotsPerRow + lot + 1}',
          'veg',
          x,
          628 - (lot + 1) * (388 / _vegLotsPerRow),
          44,
          388 / _vegLotsPerRow,
        ),

    // ---- C: อาคารยาว 3 แถว ----
    StallSlot('C-1', 'sew', 17, 677, 221, 71),
    StallSlot('C-2', 'cooked', 248, 677, 182, 71),
    StallSlot('C-3', 'restaurant', 438, 677, 222, 71),
    StallSlot('C-4', 'grill', 670, 677, 230, 71),
    StallSlot('C-5', 'sew', 17, 772, 221, 78),
    StallSlot('C-6', 'cooked', 248, 772, 182, 78),
    StallSlot('C-7', 'restaurant', 438, 772, 222, 78),
    StallSlot('C-8', 'grill', 670, 772, 230, 78),
    StallSlot('C-9', 'sew', 17, 883, 221, 75),
    StallSlot('C-10', 'cooked', 248, 883, 182, 75),
    StallSlot('C-11', 'restaurant', 438, 883, 222, 75),
    StallSlot('C-12', 'grill', 670, 883, 230, 75),

    // ---- D: แถวล่างสุด ----
    StallSlot('D-1', 'forest', 17, 990, 218, 72),
    StallSlot('D-2', 'cooked', 252, 990, 160, 72),
    StallSlot('D-3', 'fruit', 460, 990, 172, 72),
    StallSlot('D-4', 'flower', 680, 990, 218, 72),
  ];

  /// ทางเข้า 2 จุดด้านบน (ทะลุแถวของสด) และ 3 จุดด้านล่าง (ระหว่างช่วงแถวล่าง)
  static const List<MarketGate> _rawGates = [
    MarketGate(443, 6),
    MarketGate(532, 6),
    MarketGate(260, 1074, side: GateSide.bottom),
    MarketGate(435, 1074, side: GateSide.bottom),
    MarketGate(660, 1074, side: GateSide.bottom),
  ];

  /// หมุน 90° ตามเข็ม: (x, y) → (สูงเดิม − y − สูงของช่อง, x)
  /// ผลคือ "ด้านบนของผังต้นฉบับ (ของสด) ไปอยู่ขวาของจอ" ตามที่ตลาดกำหนดมา
  static StallSlot _rotate(StallSlot s) => StallSlot(
        s.id,
        s.sectionId,
        _rawSize.height - s.y - s.h,
        s.x,
        s.h,
        s.w,
      );

  static MarketGate _rotateGate(MarketGate g) => MarketGate(
        _rawSize.height - g.y,
        g.x,
        side: g.side == GateSide.top ? GateSide.right : GateSide.left,
      );

  /// เส้นทางเดินในผัง (x1,y1,x2,y2) — หมุนไปพร้อมกับผัง
  static const List<List<double>> _rawAisles = [
    [437, 272, 437, 652], // ทางเดินกลางโซนผัก
    [20, 788, 900, 788], // ระหว่างอาคารยาวแถว 1–2
    [20, 894, 900, 894], // ระหว่างแถว 2–3
    [20, 1002, 900, 1002], // ระหว่างแถว 3 กับแถวล่างสุด
  ];

  static final List<List<double>> aisles = rotated
      ? _rawAisles
          .map((a) =>
              [_rawSize.height - a[1], a[0], _rawSize.height - a[3], a[2]])
          .toList()
      : _rawAisles;

  static final List<StallSlot> slots =
      rotated ? _rawSlots.map(_rotate).toList() : _rawSlots;

  static final List<MarketGate> gates =
      rotated ? _rawGates.map(_rotateGate).toList() : _rawGates;

  static final Map<String, StallSlot> _byId = {for (final s in slots) s.id: s};
  static final Map<String, MarketSection> _sectionById = {
    for (final s in sections) s.id: s
  };

  static StallSlot? slotOf(String stallId) => _byId[stallId];

  static MarketSection sectionOf(String sectionId) =>
      _sectionById[sectionId] ?? sections.first;

  /// ย่านของแผงนี้ (null = แผงนี้ไม่ได้อยู่ในผัง เช่น แอดมินเพิ่มเองทีหลัง)
  static MarketSection? sectionOfStall(String stallId) {
    final slot = _byId[stallId];
    return slot == null ? null : sectionOf(slot.sectionId);
  }

  /// กรอบรวมของทุกแผงในย่านหนึ่ง — ใช้วาดพื้นสีประจำย่าน
  static Rect boundsOfSection(String sectionId) {
    var l = double.infinity, t = double.infinity, r = -1.0, b = -1.0;
    for (final s in slots) {
      if (s.sectionId != sectionId) continue;
      l = l < s.x ? l : s.x;
      t = t < s.y ? t : s.y;
      r = r > s.x + s.w ? r : s.x + s.w;
      b = b > s.y + s.h ? b : s.y + s.h;
    }
    if (r < 0) return Rect.zero;
    return Rect.fromLTRB(l, t, r, b);
  }

  /// หมวดสินค้าของแอป (DemoData.categories) ที่ตรงกับย่านนี้มากที่สุด
  /// ใช้ตอนสร้างแผงตามผัง เพื่อให้ตัวกรองหมวดในหน้าอื่นยังใช้ได้
  static String appCategoryOf(String sectionId) {
    switch (sectionId) {
      case 'fresh':
        return 'ประมง';
      case 'veg':
      case 'fruit':
        return 'ผัก / ผลไม้';
      case 'cooked':
      case 'restaurant':
      case 'grill':
        return 'อาหาร';
      case 'sew':
      case 'flower':
        return 'ของใช้';
      case 'forest':
        return 'ของแห้ง';
      default:
        return '';
    }
  }
}
