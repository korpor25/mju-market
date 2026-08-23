import '../models/app_user.dart';
import '../models/shop.dart';
import '../models/market_request.dart';
import '../models/stall.dart';
import '../models/promo_banner.dart';

/// ข้อมูลจำลองสำหรับ Demo Mode (รันได้เลยไม่ต้องมี Firebase)
class DemoData {
  /// บัญชีทดลอง — อีเมล/รหัสผ่านสำหรับล็อกอินใน Demo Mode
  static List<Map<String, dynamic>> demoAccounts() => [
        {
          'password': '123456',
          // เจ้าของตลาดที่เป็นแม่ค้าในตลาดด้วย — ตัวอย่างผู้ใช้หลายบทบาท
          'user': const AppUser(
            uid: 'u-admin',
            name: 'คุณสมชาย ผู้จัดการ',
            email: 'admin@maejo.com',
            phone: '081-000-0000',
            role: UserRole.admin,
            roles: [UserRole.admin, UserRole.seller],
          ),
        },
        {
          'password': '123456',
          'user': const AppUser(
            uid: 'u-seller',
            name: 'ณิชชา ใจดี',
            email: 'seller@maejo.com',
            phone: '089-111-2222',
            role: UserRole.seller,
            shopId: 's1',
          ),
        },
        {
          'password': '123456',
          'user': const AppUser(
            uid: 'u-buyer',
            name: 'คุณผู้ซื้อ ทดลอง',
            email: 'buyer@maejo.com',
            phone: '086-333-4444',
            role: UserRole.buyer,
          ),
        },
      ];

  static List<Shop> shops() => const [
        Shop(id: 's1', name: 'ร้านป้าจันทร์ อาหารเหนือ', category: 'อาหาร', ownerName: 'ณิชชา ใจดี', stallId: 'A-2', zone: 'A', rating: 4.8, reviews: 125),
        Shop(id: 's2', name: 'สวนผักป้านวล', category: 'ผักสด', ownerName: 'ป้านวล', stallId: 'A-14', zone: 'A', rating: 4.9, reviews: 88),
        Shop(id: 's3', name: 'สวนมะม่วงลุงคำ', category: 'ผลไม้', ownerName: 'ลุงคำ', stallId: 'B-3', zone: 'B', rating: 4.7, reviews: 64),
        Shop(id: 's4', name: 'ครัวข้าวซอยแม่โจ้', category: 'อาหาร', ownerName: 'ศรีนวล', stallId: 'C-11', zone: 'C', payStatus: 'due', rating: 4.6, reviews: 52),
        Shop(id: 's5', name: 'ปลาสดน้องหมวย', category: 'ประมง', ownerName: 'สมพร', stallId: 'D-7', zone: 'D', payStatus: 'bad', rating: 4.5, reviews: 40),
        Shop(id: 's6', name: 'กาแฟดอยแม่โจ้', category: 'เครื่องดื่ม', ownerName: 'วิภา ดอยคำ', stallId: 'C-3', zone: 'C', rating: 4.7, reviews: 73),
        Shop(id: 's7', name: 'สวนผักปลอดสารแม่โจ้', category: 'ผัก / ผลไม้', ownerName: 'บุญมา', stallId: 'B-1', zone: 'B', rating: 4.6, reviews: 45),
      ];

  static List<MarketRequest> requests() => const [
        MarketRequest(id: 'r1', type: RequestType.sellerApply, title: 'ร้านกาแฟดอยแม่โจ้', subtitle: 'แผง B-09 · โซนเครื่องดื่ม', amount: '฿1,500/เดือน', requesterName: 'วิภา ดอยคำ'),
        MarketRequest(id: 'r2', type: RequestType.payment, title: 'สวนผักป้านวล · A-14', subtitle: 'พร้อมเพย์ 8:02 น. · #PP-88214', amount: '฿1,500', requesterName: 'ป้านวล'),
        MarketRequest(id: 'r3', type: RequestType.move, title: 'ปลาสดน้องหมวย · D-07 → D-13', subtitle: 'เหตุผล: ใกล้ทางเข้าโซนประมง', amount: '—', requesterName: 'สมพร'),
        MarketRequest(id: 'r4', type: RequestType.booking, title: 'ร้านต้นกล้าอินทรีย์', subtitle: 'ขอจองแผง C-23 · โซนอาหาร', amount: '฿150/วัน', requesterName: 'ธนา เขียวขจี'),
        MarketRequest(id: 'r5', type: RequestType.close, title: 'ของทอดเจ๊แดง · C-05', subtitle: 'ขอปิดร้านชั่วคราว 1–15 ส.ค.', amount: '15 วัน', requesterName: 'เจ๊แดง'),
      ];

  static List<Stall> stalls() {
    final zones = {'A': 5, 'B': 5, 'C': 5, 'D': 5};
    final occupied = {
      'A-1': 'สลัดผักดอยแม่โจ้',
      'A-2': 'ร้านป้าจันทร์',
      'A-3': 'ข้าวอินทรีย์ดอยคำ',
      'B-1': 'สวนผักปลอดสาร',
      'B-2': 'สวนมะม่วงลุงคำ',
      'B-4': 'ส้มสายน้ำผึ้ง',
      'C-1': 'ครัวข้าวซอย',
      'C-3': 'กาแฟดอยแม่โจ้',
      'D-1': 'ปลาสดน้องหมวย',
      'D-2': 'หมูสดฟาร์มแม่โจ้',
    };
    final due = {'A-5', 'B-5', 'C-2'};
    final closed = {'C-5', 'B-3'};

    // หมวดประจำแผง — กำหนดรายแผง โซนหนึ่งจึงมีได้หลายหมวด
    const category = <String, String>{
      'A-1': 'ผัก / ผลไม้', 'A-2': 'อาหาร', 'A-3': 'ของแห้ง',
      'A-4': 'ผัก / ผลไม้', 'A-5': 'ของแห้ง',
      'B-1': 'ผัก / ผลไม้', 'B-2': 'ผัก / ผลไม้', 'B-3': 'ผัก / ผลไม้',
      'B-4': 'ผัก / ผลไม้', 'B-5': 'ของใช้',
      'C-1': 'อาหาร', 'C-2': 'อาหาร', 'C-3': 'เครื่องดื่ม',
      'C-4': 'เครื่องดื่ม', 'C-5': 'อาหาร',
      'D-1': 'ประมง', 'D-2': 'ประมง', 'D-3': 'ประมง',
      'D-4': 'ของใช้', 'D-5': 'ของแห้ง',
    };

    // ค่าเช่าฐานต่อวันตามหมวด (บาท) — หมวดที่ขายดีกว่าคิดแพงกว่า
    const basePrice = <String, int>{
      'อาหาร': 220,
      'เครื่องดื่ม': 200,
      'ประมง': 180,
      'ผัก / ผลไม้': 150,
      'ของแห้ง': 130,
      'ของใช้': 120,
    };

    final list = <Stall>[];
    zones.forEach((z, n) {
      for (var i = 1; i <= n; i++) {
        final id = '$z-$i';
        String st = 'empty';
        if (occupied.containsKey(id)) {
          st = 'occupied';
        } else if (due.contains(id)) {
          st = 'due';
        } else if (closed.contains(id)) {
          st = 'closed';
        }
        final cat = category[id] ?? '';
        final base = basePrice[cat] ?? 150;
        list.add(Stall(
          id: id,
          zone: z,
          status: st,
          shopName: occupied[id],
          category: cat,
          // แผงเลข 1-2 อยู่ติดทางเข้าตลาด คนเดินผ่านเยอะกว่า จึงบวกเพิ่ม
          pricePerDay: i <= 2 ? base + 30 : base,
        ));
      }
    });
    return list;
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

  static const List<String> categories = [
    'อาหาร', 'ผัก / ผลไม้', 'เครื่องดื่ม', 'ของใช้', 'ประมง', 'ของแห้ง',
  ];
}
