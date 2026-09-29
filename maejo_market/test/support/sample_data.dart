import 'package:maejo_market/data/market_layout.dart';
import 'package:maejo_market/models/promo_banner.dart';
import 'package:maejo_market/models/shop.dart';
import 'package:maejo_market/models/stall.dart';

/// ข้อมูลตัวอย่างสำหรับเทสต์ UI — ใส่ลง appState ตรง ๆ แทนการต่อ Firebase
class SampleData {
  static List<Shop> shops() => const [
        Shop(id: 's1', name: 'ร้านป้าจันทร์ อาหารเหนือ', category: 'อาหาร', ownerName: 'ณิชชา ใจดี', stallId: 'C-3', zone: 'C', rating: 4.8, reviews: 125),
        Shop(id: 's2', name: 'สวนผักป้านวล', category: 'ผักสด', ownerName: 'ป้านวล', stallId: 'B-1', zone: 'B', rating: 4.9, reviews: 88),
        Shop(id: 's3', name: 'สวนมะม่วงลุงคำ', category: 'ผลไม้', ownerName: 'ลุงคำ', stallId: 'D-3', zone: 'D', rating: 4.7, reviews: 64),
        Shop(id: 's4', name: 'ครัวข้าวซอยแม่โจ้', category: 'อาหาร', ownerName: 'ศรีนวล', stallId: 'C-7', zone: 'C', payStatus: 'due', rating: 4.6, reviews: 52),
        Shop(id: 's5', name: 'ปลาสดน้องหมวย', category: 'ประมง', ownerName: 'สมพร', stallId: 'A-4', zone: 'A', payStatus: 'bad', rating: 4.5, reviews: 40),
        Shop(id: 's6', name: 'กาแฟดอยแม่โจ้', category: 'เครื่องดื่ม', ownerName: 'วิภา ดอยคำ', stallId: 'C-11', zone: 'C', rating: 4.7, reviews: 73),
        Shop(id: 's7', name: 'สวนผักปลอดสารแม่โจ้', category: 'ผัก / ผลไม้', ownerName: 'บุญมา', stallId: 'B-4', zone: 'B', rating: 4.6, reviews: 45),
      ];

  /// แผงทั้งหมด "ตามผังจริง" — ตำแหน่งมาจาก [MarketLayout] จะได้ไม่ต้องไล่แก้สองที่
  static List<Stall> stalls() {
    const occupied = <String, String>{
      'A-4': 'ปลาสดน้องหมวย',
      'A-2': 'หมูสดฟาร์มแม่โจ้',
      'A-9': 'ไข่ไก่สดบ้านสวน',
      'B-1': 'สวนผักป้านวล',
      'B-4': 'สวนผักปลอดสารแม่โจ้',
      'B-5': 'ผักดอยแม่โจ้',
      'C-3': 'ร้านป้าจันทร์ อาหารเหนือ',
      'C-7': 'ครัวข้าวซอยแม่โจ้',
      'C-11': 'กาแฟดอยแม่โจ้',
      'C-1': 'ร้านเย็บผ้าแม่ประนอม',
      'D-1': 'ของป่าลุงมา',
      'D-3': 'สวนมะม่วงลุงคำ',
      'D-4': 'ดอกไม้สดแม่โจ้',
    };
    const due = {'C-7', 'B-5', 'A-2'};
    const closed = {'C-1', 'B-6'};

    // แผงติดทางเข้าคนเดินผ่านเยอะกว่า คิดค่าเช่าเพิ่ม
    const nearGate = {'A-3', 'A-4', 'D-1', 'D-2', 'D-3', 'D-4'};

    return [
      for (final slot in MarketLayout.slots)
        Stall(
          id: slot.id,
          zone: slot.id.split('-').first,
          // ค้างชำระ/ปิดปรับปรุง เป็นสถานะของแผงที่ "มีร้านอยู่แล้ว"
          // จึงต้องตรวจก่อน ไม่งั้นจะถูกกลบเป็น occupied ทั้งหมด
          status: due.contains(slot.id)
              ? 'due'
              : closed.contains(slot.id)
                  ? 'closed'
                  : occupied.containsKey(slot.id)
                      ? 'occupied'
                      : 'empty',
          shopName: occupied[slot.id],
          category: MarketLayout.appCategoryOf(slot.sectionId),
          pricePerDay: MarketLayout.sectionOf(slot.sectionId).pricePerDay +
              (nearGate.contains(slot.id) ? 25 : 0),
        ),
    ];
  }

  /// แบนเนอร์ตัวอย่างหน้าแรก — ปกติแอดมินจัดการเองผ่านหน้าจัดการแบนเนอร์
  static List<PromoBanner> banners() => const [
        PromoBanner(
          id: 'bn-1',
          title: 'เทศกาลผักสด',
          subtitle: 'จากชุมชนแม่โจ้',
          order: 0,
        ),
        PromoBanner(
          id: 'bn-2',
          title: 'ของสดจากฟาร์ม',
          subtitle: 'ส่งตรงทุกเช้า',
          order: 1,
        ),
      ];
}
