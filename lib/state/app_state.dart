import 'package:flutter/foundation.dart';

import '../app_config.dart';
import '../models/app_user.dart';
import '../models/shop.dart';
import '../models/market_request.dart';
import '../models/stall.dart';
import '../models/promo_banner.dart';
import '../models/product.dart';
import '../models/app_notification.dart';
import '../models/review.dart';
import '../models/sale.dart';
import 'firebase_backend.dart';

/// สถานะกลางของแอป (auth + ข้อมูล) — ข้อมูลทั้งหมดมาจาก Firebase
///
/// ใช้แบบ singleton: `appState`
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final FirebaseBackend _fb = FirebaseBackend();

  bool ready = false;
  AppUser? user;

  /// เข้าชมตลาดโดยไม่ลงทะเบียน — เห็นร้าน สินค้า ผังตลาด และโปรโมชั่นได้ทั้งหมด
  /// แต่ทำสิ่งที่ผูกกับบัญชีไม่ได้ (ติดตามร้าน รีวิว แจ้งเตือน เปิดร้าน)
  bool guest = false;

  /// กำลังเข้าชมแบบไม่ลงทะเบียนอยู่จริง (ล็อกอินแล้ว = ไม่ใช่ผู้เยี่ยมชมอีกต่อไป)
  bool get isGuest => guest && user == null;

  List<Shop> shops = [];
  List<MarketRequest> requests = [];
  List<Stall> stalls = [];
  List<PromoBanner> banners = [];

  /// ร้านทั้งหมดที่ผู้ใช้คนนี้เป็นเจ้าของ (คนหนึ่งเปิดได้หลายร้าน)
  List<Shop> myShops = [];

  /// ร้านที่อยู่บนแผงนี้ — null = แผงว่าง หรือร้านถูกลบไปแล้วแต่แผงยังค้างชื่อไว้
  Shop? shopOfStall(String stallId) {
    for (final s in shops) {
      if (s.stallId == stallId) return s;
    }
    return null;
  }

  // ข้อมูลของผู้ขายที่ล็อกอิน
  Shop? myShop;
  List<Product> products = [];

  /// ยอดขายของร้านที่ล็อกอิน (เรียงใหม่ → เก่า)
  List<Sale> sales = [];

  // การแจ้งเตือนของผู้ใช้ที่ล็อกอิน
  List<AppNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.read).length;

  // สถิติสำหรับแอดมิน
  int sellerCount = 0;

  bool get isLoggedIn => user != null;
  int get pendingCount => requests.where((r) => r.status == 'pending').length;

  // ---- สถิติจริงสำหรับแดชบอร์ดแอดมิน ----
  int get shopCount => shops.length;
  int get approvedCount => requests.where((r) => r.status == 'approved').length;
  int get rejectedCount => requests.where((r) => r.status == 'rejected').length;
  int get newBookingCount =>
      requests.where((r) => r.type == RequestType.booking && r.status == 'pending').length;
  /// ค่าเช่ารายเดือนของร้านหนึ่ง = ราคาแผงต่อวัน x จำนวนวันต่อรอบ
  /// ร้านที่ยังไม่ได้จองแผงยังไม่ต้องจ่าย
  int monthlyFeeFor(Shop s) {
    if (!s.hasStall) return 0;
    final st = stalls.where((x) => x.id == s.stallId);
    return st.isEmpty ? 0 : st.first.pricePerDay * AppConfig.billingDays;
  }

  /// รายได้ค่าเช่ารวมต่อเดือนของตลาด — รวมจากราคาแผงจริงที่ถูกเช่าอยู่
  int get monthlyRent => shops.fold<int>(0, (a, s) => a + monthlyFeeFor(s));

  /// ร้านนี้ค้างชำระรอบปัจจุบันหรือยัง
  /// ไม่เก็บสถานะค้างไว้ตรง ๆ แต่คำนวณจากวันที่จ่ายล่าสุด จะได้ไม่ต้องมี cron
  bool isPaymentDue(Shop s) {
    if (!s.hasStall) return false;
    final last = s.lastPaidAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= AppConfig.billingDays;
  }

  /// มีคำขอแจ้งชำระของร้านนี้รออยู่ไหม (แจ้งไปแล้วอย่าให้แจ้งซ้ำ)
  bool hasPendingPayment(String shopId) => requests.any(
      (r) => r.type == RequestType.payment && r.status == 'pending' && r.shopId == shopId);

  /// ผู้ขายแจ้งชำระค่าเช่า
  Future<String?> submitPayment({
    required Shop shop,
    required int amount,
    String slipUrl = '',
    String note = '',
  }) async {
    final u = user;
    if (u == null) return 'ยังไม่ได้เข้าสู่ระบบ';
    if (amount <= 0) return 'ยังไม่มียอดที่ต้องชำระ';
    if (hasPendingPayment(shop.id)) return 'มีรายการแจ้งชำระรออยู่แล้ว';

    await _fb.addPayment(
      uid: u.uid,
      shopId: shop.id,
      shopName: shop.name,
      stallId: shop.stallId,
      amount: amount,
      by: u.name,
      slipUrl: slipUrl,
      note: note,
    );
    requests = await _fb.fetchRequests();
    notifyListeners();
    return null;
  }

  Future<void> init() async {
    await _fb.init();
    _fb.watchAuth((u) async {
      user = u;
      // ล็อกอินแล้วก็ไม่ใช่ผู้เยี่ยมชมอีก ไม่งั้นออกจากระบบแล้วจะค้างอยู่ในตลาดแทนหน้าล็อกอิน
      if (u != null) guest = false;
      if (u != null) {
        await _loadData();
      } else if (guest) {
        await _loadPublicData();
      }
      ready = true;
      notifyListeners();
    });
  }

  /// แบนเนอร์ที่เปิดใช้งาน เรียงตามลำดับที่แอดมินตั้งไว้
  List<PromoBanner> get activeBanners {
    final list = banners.where((b) => b.active).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// ข้อมูลที่กฎ Firestore เปิดให้ทุกคนอ่าน — ผู้เยี่ยมชมที่ยังไม่ล็อกอินก็เห็นชุดนี้
  Future<void> _loadPublicData() async {
    shops = await _fb.fetchShops();
    // ถ้า Firestore ยังไม่มีแผง ผังต้องว่างจริง ๆ
    // (แอดมินมีปุ่ม "สร้างแผงตามผังตลาด" ในหน้าจัดการแผงไว้เติมให้ครบ)
    stalls = await _fb.fetchStalls();
    // แบนเนอร์เป็นของเสริม — ถ้า rules ยังไม่ได้ deploy หรือปฏิเสธ
    // ต้องไม่ทำให้ข้อมูลที่เหลือ (ร้าน/สินค้า/แจ้งเตือน) โหลดไม่ขึ้นไปด้วย
    try {
      banners = await _fb.fetchBanners();
    } catch (_) {
      banners = [];
    }
  }

  Future<void> _loadData() async {
    await _loadPublicData();
    requests = await _fb.fetchRequests();

    final u = user;
    // ผู้ขาย: ร้านของตัวเองดูจาก ownerUid ไม่ใช่จากรหัสร้าน = uid แบบเดิม
    if (u != null && u.can(UserRole.seller)) {
      myShops = shops.where((s) => s.ownerUid == u.uid).toList();
      // users.shopId คือ "ร้านที่เลือกอยู่" ถ้าค่าที่เก็บไว้ใช้ไม่ได้แล้วให้ตกไปที่ร้านแรก
      final picked = myShops.where((s) => s.id == u.shopId);
      myShop = picked.isNotEmpty ? picked.first : (myShops.isNotEmpty ? myShops.first : null);
    } else {
      myShops = [];
      myShop = null;
    }

    final shopId = myShop?.id;
    if (shopId != null) {
      products = await _fb.fetchProducts(shopId);
      // ยอดขายอ่านได้เฉพาะร้านของตัวเอง — ถ้า rules ปฏิเสธ อย่าให้ทั้งการโหลดพัง
      try {
        sales = await _fb.fetchSales(shopId);
      } catch (_) {
        sales = [];
      }
    } else {
      products = [];
      sales = [];
    }
    // แอดมิน: นับจำนวนผู้ขาย
    if (u != null && u.role == UserRole.admin) {
      sellerCount = await _fb.fetchSellerCount();
    }

    // การแจ้งเตือนของผู้ใช้
    if (u != null) {
      notifications = await _fb.fetchNotifications(u.uid);
    } else {
      notifications = [];
    }
  }

  /// รีเฟรชเฉพาะการแจ้งเตือน (เรียกตอนเปิดกระดิ่ง / pull-to-refresh)
  ///
  /// โหลดไม่ได้ (เน็ตหลุด/สิทธิ์ไม่พอ) ให้คงรายการเดิมไว้ ดีกว่าทำให้ปุ่มกระดิ่งพังทั้งปุ่ม
  Future<void> refreshNotifications() async {
    final u = user;
    if (u == null) return;
    try {
      notifications = await _fb.fetchNotifications(u.uid);
    } catch (e) {
      debugPrint('fetchNotifications failed: $e');
      return;
    }
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await _fb.markNotificationRead(id);
    notifications = notifications
        .map((n) => n.id == id
            ? AppNotification(id: n.id, uid: n.uid, title: n.title, body: n.body, read: true, createdAt: n.createdAt)
            : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final u = user;
    if (u != null) {
      try {
        await _fb.markAllNotificationsRead(u.uid);
      } catch (e) {
        // ทำเครื่องหมายว่าอ่านไม่สำเร็จ ไม่ใช่เรื่องที่ต้องเด้ง error ใส่ผู้ใช้
        debugPrint('markAllNotificationsRead failed: $e');
      }
    }
    notifications = notifications
        .map((n) => AppNotification(id: n.id, uid: n.uid, title: n.title, body: n.body, read: true, createdAt: n.createdAt))
        .toList();
    notifyListeners();
  }

  // ---------------- LINE ----------------

  /// ขอรหัสผูกบัญชี LINE (6 ตัว) — คืน null ถ้ายังไม่ได้ตั้งค่าหรือทำไม่สำเร็จ
  Future<String?> createLineLinkCode() async {
    final u = user;
    if (u == null) return null;
    try {
      return await _fb.createLineLinkCode(u.uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> unlinkLine() async {
    final u = user;
    if (u == null) return;
    await _fb.unlinkLine(u.uid);
    user = u.copyWith(clearLine: true);
    notifyListeners();
  }

  /// ดึงข้อมูลผู้ใช้ใหม่จาก Firestore — ใช้เช็คว่าผูกไลน์สำเร็จหรือยัง
  /// (การผูกเกิดขึ้นฝั่งเซิร์ฟเวอร์ตอนผู้ใช้พิมพ์รหัสในแชต แอปจึงต้องถามเอง)
  Future<bool> refreshUser() async {
    final u = user;
    if (u == null) return false;
    final fresh = await _fb.fetchUser(u.uid);
    if (fresh == null) return false;
    user = fresh;
    notifyListeners();
    return true;
  }

  // ---------------- AUTH ----------------

  /// เข้าชมตลาดโดยไม่ลงทะเบียน — พาเข้าหน้าร้านค้าทันทีแล้วค่อยเติมข้อมูลตามมา
  /// (ข้อมูลสาธารณะอาจโหลดไว้แล้วจากรอบก่อน จึงไม่ควรกั้นหน้าจอไว้รอ)
  Future<void> continueAsGuest() async {
    if (user != null) return;
    guest = true;
    notifyListeners();
    try {
      await _loadPublicData();
    } catch (e) {
      debugPrint('guest load failed: $e');
    }
    notifyListeners();
  }

  /// ออกจากโหมดผู้เยี่ยมชมกลับไปหน้าเข้าสู่ระบบ (ข้อมูลตลาดที่โหลดไว้ใช้ต่อได้)
  void leaveGuest() {
    if (!guest) return;
    guest = false;
    notifyListeners();
  }

  /// คืนค่า null = สำเร็จ, หรือข้อความ error (ภาษาไทย)
  Future<String?> signIn(String email, String password) =>
      _fb.signIn(email.trim().toLowerCase(), password);

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? shopName,
    String? shopCategory,
  }) async {
    return _fb.signUp(
      name: name, email: email.trim().toLowerCase(), password: password, phone: phone,
      role: role, shopName: shopName, shopCategory: shopCategory,
    );
  }

  Future<void> signOut() async {
    await _fb.signOut();
    user = null;
    guest = false;
    notifyListeners();
  }

  /// ส่งอีเมลรีเซ็ตรหัสผ่าน — คืน null = สำเร็จ
  Future<String?> resetPassword(String email) => _fb.resetPassword(email);

  /// เปลี่ยนรหัสผ่านของตัวเอง — คืน null = สำเร็จ
  Future<String?> changePassword(String current, String newPass) =>
      _fb.changePassword(current, newPass);

  // ---------------- USER MANAGEMENT (admin) ----------------

  List<AppUser> allUsers = [];

  Future<void> fetchAllUsers() async {
    allUsers = await _fb.fetchUsers();
    notifyListeners();
  }

  Future<void> setUserStatus(String uid, String status) async {
    await _fb.setUserStatus(uid, status);
    allUsers = await _fb.fetchUsers();
    sellerCount = await _fb.fetchSellerCount();
    notifyListeners();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _fb.setUserRole(uid, role);
    allUsers = await _fb.fetchUsers();
    sellerCount = await _fb.fetchSellerCount();
    notifyListeners();
  }

  /// แอดมินให้/ถอนหลายบทบาทกับผู้ใช้คนหนึ่ง
  Future<void> setUserRoles(String uid, List<UserRole> roles) async {
    if (roles.isEmpty) return;
    await _fb.setUserRoles(uid, roles.map((r) => r.id).toList());
    allUsers = await _fb.fetchUsers();
    sellerCount = await _fb.fetchSellerCount();
    // ถ้าแก้บทบาทของตัวเอง ให้สถานะในแอปตรงกันทันที
    final u = user;
    if (u != null && u.uid == uid) {
      user = u.copyWith(roles: roles, role: roles.contains(u.role) ? u.role : roles.first);
      await _loadData();
    }
    notifyListeners();
  }

  /// สลับบทบาทที่กำลังใช้งาน (สำหรับผู้ใช้ที่มีหลายบทบาท)
  /// เปลี่ยนแค่มุมมอง ไม่ได้เพิ่ม/ลดสิทธิ์
  Future<void> switchRole(UserRole role) async {
    final u = user;
    if (u == null || u.role == role || !u.can(role)) return;
    user = u.copyWith(role: role);
    notifyListeners();
    await _fb.setActiveRole(u.uid, role.id);
    // ข้อมูลที่โหลดขึ้นกับบทบาท (ร้าน/สินค้า/ยอดขาย/จำนวนผู้ขาย) ต้องโหลดใหม่
    await _loadData();
    notifyListeners();
  }

  // ---------------- SHOP (ผู้ขายแก้ไขร้านตัวเอง) ----------------

  Future<String?> updateShop(Map<String, dynamic> data) async {
    final shopId = myShop?.id;
    if (shopId == null) return 'ยังไม่มีร้าน';
    await _fb.updateShop(shopId, data);
    myShop = await _fb.fetchShop(shopId);
    shops = await _fb.fetchShops();
    notifyListeners();
    return null;
  }

  /// ให้หน้าแอดมินเปิดแท็บนี้ตอนเข้ามาครั้งถัดไป (null = ไม่ระบุ)
  /// ใช้ตอนยื่นขอเปิดร้านเสร็จแล้วพาไปหน้าอนุมัติต่อทันที
  int? pendingAdminTab;

  void requestAdminTab(int index) {
    pendingAdminTab = index;
    notifyListeners();
  }

  /// สลับร้านที่กำลังจัดการ (สำหรับคนที่เปิดหลายร้าน)
  Future<void> selectShop(String shopId) async {
    final u = user;
    if (u == null || myShop?.id == shopId) return;
    if (!myShops.any((s) => s.id == shopId)) return;
    user = u.copyWith(shopId: shopId);
    notifyListeners();
    await _fb.setSelectedShop(u.uid, shopId);
    await _loadData();
    notifyListeners();
  }

  /// คำขอเปิดร้านของตัวเองที่ยังรออนุมัติ (null = ไม่มี)
  MarketRequest? get myPendingShopRequest {
    final u = user;
    if (u == null || u.uid.isEmpty) return null;
    for (final r in requests) {
      if (r.type == RequestType.sellerApply && r.status == 'pending' && r.uid == u.uid) {
        return r;
      }
    }
    return null;
  }

  /// ยื่นขอเปิดร้านจากบัญชีที่มีอยู่แล้ว
  /// เดิมทำได้เฉพาะตอนสมัครสมาชิก บัญชีเดิมจึงไม่มีทางเปิดร้าน
  Future<String?> applyForShop({
    required String shopName,
    required String category,
    String description = '',
    String ownerName = '',
    String phone = '',
  }) async {
    final u = user;
    if (u == null) return 'ยังไม่ได้เข้าสู่ระบบ';
    if (shopName.trim().isEmpty) return 'กรอกชื่อร้านก่อน';
    if (myPendingShopRequest != null) return 'มีคำขอเปิดร้านรออนุมัติอยู่แล้ว';
    // กันไว้อีกชั้นนอกจากปุ่มในฟอร์ม — ผลอนุมัติต้องแจ้งเข้าไลน์ได้ (แอดมินอนุมัติตัวเองได้ จึงยกเว้น)
    if (AppConfig.lineReady && !u.lineLinked && !u.can(UserRole.admin)) {
      return 'เชื่อมต่อ LINE ก่อนยื่นขอเปิดร้าน';
    }

    await _fb.addSellerApply(
      uid: u.uid,
      shopName: shopName.trim(),
      shopCategory: category,
      description: description.trim(),
      requesterName: ownerName.trim().isEmpty ? u.name : ownerName.trim(),
      phone: phone.trim().isEmpty ? u.phone : phone.trim(),
    );
    requests = await _fb.fetchRequests();
    notifyListeners();
    return null;
  }

  // ---------------- APPROVALS ----------------

  Future<void> setRequestStatus(String id, String status) async {
    if (status == 'approved') {
      await _fb.approveRequest(id);
    } else {
      await _fb.rejectRequest(id);
    }
    // อนุมัติแล้วอาจสร้างร้าน/จัดแผงใหม่ — โหลดข้อมูลที่เกี่ยวข้องใหม่
    requests = await _fb.fetchRequests();
    shops = await _fb.fetchShops();
    stalls = await _fb.fetchStalls();

    // ถ้าอนุมัติคำขอของตัวเอง (เจ้าของตลาดที่ขายเองด้วย) ต้องรีเฟรชผู้ใช้ด้วย
    // เพราะ approveRequest เขียน shopId ลง Firestore แต่ user ในหน่วยความจำ
    // ถูกตั้งค่าจาก watchAuth เท่านั้น ซึ่งยิงตอน login/logout — ไม่งั้นร้านจะไม่ขึ้น
    final me = user;
    if (me != null) {
      final fresh = await _fb.fetchUser(me.uid);
      if (fresh != null) {
        // เก็บบทบาทที่กำลังใช้อยู่ไว้ ไม่ให้เด้งกลับเป็นบทบาทหลัก
        user = me.can(fresh.role) ? fresh : fresh.copyWith(role: me.role);
        await _loadData();
      }
    }
    notifyListeners();
  }

  Future<void> approveAll() async {
    final pending = requests.where((r) => r.status == 'pending').toList();
    for (final r in pending) {
      await setRequestStatus(r.id, 'approved');
    }
  }

  List<MarketRequest> get pendingRequests =>
      requests.where((r) => r.status == 'pending').toList();

  // ---------------- STALLS (แอดมินจัดการแผง) ----------------

  /// เลขแผงถัดไปที่ยังไม่ถูกใช้ในโซนนั้น
  int nextStallNumber(String zone) {
    var max = 0;
    for (final s in stalls) {
      if (s.zone == zone && s.number > max) max = s.number;
    }
    return max + 1;
  }

  List<String> get zones {
    final z = stalls.map((s) => s.zone).where((s) => s.isNotEmpty).toSet().toList()..sort();
    return z;
  }

  Future<String?> saveStall(Stall s, {bool isNew = false}) async {
    if (s.id.trim().isEmpty) return 'ต้องมีรหัสแผง';
    if (isNew && stalls.any((x) => x.id == s.id)) return 'มีแผง ${s.id} อยู่แล้ว';

    await _fb.upsertStall(s);
    stalls = await _fb.fetchStalls();
    notifyListeners();
    return null;
  }

  /// ลบแผงได้เฉพาะแผงว่าง — แผงที่มีผู้เช่าอยู่ถ้าลบจะทำให้ร้านลอย
  Future<String?> removeStall(String id) async {
    final target = stalls.where((x) => x.id == id);
    if (target.isNotEmpty && !target.first.isEmpty) {
      return 'ลบไม่ได้ — แผงนี้มีผู้เช่าอยู่ ให้ย้ายหรือปิดร้านก่อน';
    }
    await _fb.deleteStall(id);
    stalls = await _fb.fetchStalls();
    notifyListeners();
    return null;
  }

  // ---------------- BOOKING ----------------

  Future<void> bookStall(String stallId, String shopName) async {
    final stall = stalls.where((s) => s.id == stallId);
    await _fb.addBooking(
      stallId,
      shopName,
      user?.name ?? '',
      uid: user?.uid ?? '',
      shopId: myShop?.id ?? '',
      pricePerDay: stall.isNotEmpty ? stall.first.pricePerDay : 150,
    );
    requests = await _fb.fetchRequests();
    notifyListeners();
  }

  // ---------------- PRODUCTS (สินค้าของผู้ขาย) ----------------

  Future<String?> addProduct(String name, double price, {String imageUrl = ''}) async {
    final shopId = myShop?.id;
    if (shopId == null) return 'ยังไม่มีร้าน — รอผู้ดูแลระบบอนุมัติก่อน';
    try {
      final p = await _fb.addProduct(shopId, name, price, imageUrl: imageUrl);
      products = [p, ...products];
    } catch (e) {
      return 'เพิ่มสินค้าไม่สำเร็จ: $e';
    }
    notifyListeners();
    return null;
  }

  /// แก้ไขสินค้า (ชื่อ/ราคา/รูป) — เดิมทำได้แค่เพิ่มกับลบ
  Future<String?> editProduct(
    String id, {
    required String name,
    required double price,
    required String imageUrl,
  }) async {
    final data = {'name': name, 'price': price, 'imageUrl': imageUrl};
    await _fb.updateProduct(id, data);
    products = products
        .map((p) => p.id == id ? p.copyWith(name: name, price: price, imageUrl: imageUrl) : p)
        .toList();
    notifyListeners();
    return null;
  }

  // ---------------- BANNERS (แอดมินจัดการแบนเนอร์หน้าแรก) ----------------

  Future<void> saveBanner(PromoBanner b) async {
    if (b.id.isEmpty) {
      final id = await _fb.addBanner(b);
      banners = [...banners, PromoBanner.fromMap(id, b.toMap())];
    } else {
      await _fb.updateBanner(b.id, b.toMap());
      banners = banners.map((x) => x.id == b.id ? b : x).toList();
    }
    notifyListeners();
  }

  Future<void> removeBanner(String id) async {
    await _fb.deleteBanner(id);
    banners = banners.where((b) => b.id != id).toList();
    notifyListeners();
  }

  Future<void> removeProduct(String id) async {
    await _fb.deleteProduct(id);
    products = products.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> toggleProduct(String id, bool available) async {
    await _fb.setProductAvailable(id, available);
    products = products
        .map((p) => p.id == id ? p.copyWith(available: available) : p)
        .toList();
    notifyListeners();
  }

  /// ดึงสินค้าของร้านใดๆ (ใช้ในหน้ารายละเอียดร้านฝั่งผู้ซื้อ)
  Future<List<Product>> fetchProductsFor(String shopId) => _fb.fetchProducts(shopId);

  // ---------------- SALES (รายงานยอดขาย) ----------------

  /// ยอดขายวันนี้ของร้านที่ล็อกอิน
  double get todayRevenue =>
      SalesStats(SalesStats.filter(sales, SalePeriod.today)).revenue;

  /// จำนวนบิลที่บันทึกวันนี้
  int get todayBillCount => SalesStats.filter(sales, SalePeriod.today).length;

  Future<void> refreshSales() async {
    final shopId = myShop?.id;
    if (shopId == null) return;
    sales = await _fb.fetchSales(shopId);
    notifyListeners();
  }

  /// บันทึกการขาย 1 รายการ — คืน null = สำเร็จ, หรือข้อความ error
  Future<String?> recordSale({
    required Product product,
    required int qty,
    double? unitPrice,
    String note = '',
  }) async {
    final shop = myShop;
    if (shop == null) return 'ยังไม่มีร้าน — รอผู้ดูแลระบบอนุมัติก่อน';
    if (qty <= 0) return 'จำนวนต้องมากกว่า 0';
    final price = unitPrice ?? product.price;
    if (price < 0) return 'ราคาต้องไม่ติดลบ';

    final draft = Sale(
      id: '',
      shopId: shop.id,
      shopName: shop.name,
      productId: product.id,
      productName: product.name,
      price: price,
      qty: qty,
      note: note.trim(),
    );

    final saved = await _fb.addSale(draft);
    sales = [saved, ...sales];
    notifyListeners();
    return null;
  }

  Future<void> deleteSale(String id) async {
    await _fb.deleteSale(id);
    sales = sales.where((s) => s.id != id).toList();
    notifyListeners();
  }

  /// ยอดขายทุกร้าน (รายงานภาพรวมของแอดมิน)
  Future<List<Sale>> fetchAllSales() => _fb.fetchAllSales();

  // ---------------- REVIEWS ----------------

  Future<List<Review>> fetchReviewsFor(String shopId) => _fb.fetchReviews(shopId);

  /// เพิ่ม/แก้รีวิวของผู้ใช้ปัจจุบัน — คืน null = สำเร็จ, หรือข้อความ error
  Future<String?> addReview(String shopId, int rating, String comment) async {
    final u = user;
    if (u == null) return 'กรุณาเข้าสู่ระบบก่อนรีวิว';
    if (rating < 1 || rating > 5) return 'กรุณาให้คะแนน 1–5 ดาว';
    await _fb.addReview(shopId, u.uid, u.name, rating, comment.trim());
    shops = await _fb.fetchShops(); // รีเฟรชค่าเฉลี่ยในการ์ดร้าน
    if (myShop?.id == shopId) myShop = await _fb.fetchShop(shopId);
    notifyListeners();
    return null;
  }

  Future<void> deleteReview(String reviewId, String shopId) async {
    await _fb.deleteReview(reviewId, shopId);
    shops = await _fb.fetchShops();
    if (myShop?.id == shopId) myShop = await _fb.fetchShop(shopId);
    notifyListeners();
  }

  /// ดึงรีวิวทั้งหมด (หน้า moderation ของแอดมิน)
  Future<List<Review>> fetchAllReviews() => _fb.fetchAllReviews();

  // ---------------- INSPECTIONS (ตรวจมาตรฐานร้าน) ----------------

  /// บันทึกผลการตรวจมาตรฐานร้าน — คืน null = สำเร็จ
  Future<String?> saveInspection({
    required String shopId,
    required String shopName,
    required Map<String, int> scores,
    required String note,
  }) async {
    final u = user;
    if (u == null) return 'กรุณาเข้าสู่ระบบก่อน';
    if (scores.values.any((v) => v < 1)) return 'ให้คะแนนให้ครบทุกข้อก่อนบันทึก';
    final avg = scores.values.reduce((a, b) => a + b) / scores.length;
    try {
      await _fb.saveInspection(
        shopId: shopId,
        shopName: shopName,
        scores: scores,
        avg: double.parse(avg.toStringAsFixed(2)),
        note: note.trim(),
        byUid: u.uid,
        byName: u.name,
      );
    } catch (e) {
      return 'บันทึกไม่สำเร็จ: $e';
    }
    notifyListeners();
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchInspections({String? shopId}) =>
      _fb.fetchInspections(shopId: shopId);

  // ---------------- FAVORITES (ร้านที่ติดตาม) ----------------

  List<String> get favoriteIds => user?.favorites ?? const [];
  bool isFavorite(String shopId) => favoriteIds.contains(shopId);
  List<Shop> get favoriteShops => shops.where((s) => favoriteIds.contains(s.id)).toList();

  /// สลับสถานะติดตามร้าน — คืน true = ติดตามอยู่หลังกด, false = เลิกติดตาม
  Future<bool> toggleFavorite(String shopId) async {
    final u = user;
    if (u == null) return false;
    final add = !u.favorites.contains(shopId);
    final list = [...u.favorites];
    if (add) {
      list.add(shopId);
    } else {
      list.remove(shopId);
    }
    user = u.copyWith(favorites: list);
    notifyListeners();
    await _fb.toggleFavorite(u.uid, shopId, add);
    return add;
  }
}

/// shortcut
final appState = AppState.instance;
