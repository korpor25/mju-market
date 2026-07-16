import 'package:flutter/foundation.dart';

import '../app_config.dart';
import '../data/demo_data.dart';
import '../models/app_user.dart';
import '../models/shop.dart';
import '../models/market_request.dart';
import '../models/stall.dart';
import 'firebase_backend.dart';

/// สถานะกลางของแอป (auth + ข้อมูล) รองรับทั้ง Demo Mode และ Firebase
///
/// ใช้แบบ singleton: `appState`
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final FirebaseBackend? _fb = AppConfig.useFirebase ? FirebaseBackend() : null;

  bool ready = false;
  AppUser? user;

  List<Shop> shops = [];
  List<MarketRequest> requests = [];
  List<Stall> stalls = [];

  // บัญชี demo ในหน่วยความจำ (email -> {password, user})
  final Map<String, Map<String, dynamic>> _demoAccounts = {};

  bool get isLoggedIn => user != null;
  int get pendingCount => requests.where((r) => r.status == 'pending').length;

  Future<void> init() async {
    if (_fb != null) {
      await _fb.init();
      _fb.watchAuth((u) async {
        user = u;
        if (u != null) await _loadData();
        ready = true;
        notifyListeners();
      });
    } else {
      // ---- Demo Mode ----
      for (final a in DemoData.demoAccounts()) {
        final u = a['user'] as AppUser;
        _demoAccounts[u.email.toLowerCase()] = a;
      }
      _seedDemoData();
      ready = true;
      notifyListeners();
    }
  }

  void _seedDemoData() {
    shops = DemoData.shops();
    requests = DemoData.requests();
    stalls = DemoData.stalls();
  }

  Future<void> _loadData() async {
    if (_fb == null) return;
    shops = await _fb.fetchShops();
    requests = await _fb.fetchRequests();
    stalls = await _fb.fetchStalls();
    if (stalls.isEmpty) stalls = DemoData.stalls();
  }

  // ---------------- AUTH ----------------

  /// คืนค่า null = สำเร็จ, หรือข้อความ error (ภาษาไทย)
  Future<String?> signIn(String email, String password) async {
    email = email.trim().toLowerCase();
    if (_fb != null) {
      final err = await _fb.signIn(email, password);
      return err;
    }
    // Demo
    final acc = _demoAccounts[email];
    if (acc == null) return 'ไม่พบบัญชีนี้ (ลอง admin@maejo.com)';
    if (acc['password'] != password) return 'รหัสผ่านไม่ถูกต้อง';
    user = acc['user'] as AppUser;
    notifyListeners();
    return null;
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? shopName,
    String? shopCategory,
  }) async {
    email = email.trim().toLowerCase();
    if (_fb != null) {
      return _fb.signUp(
        name: name, email: email, password: password, phone: phone,
        role: role, shopName: shopName, shopCategory: shopCategory,
      );
    }
    // Demo
    if (_demoAccounts.containsKey(email)) return 'อีเมลนี้ถูกใช้แล้ว';
    final newUser = AppUser(
      uid: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      // ผู้ขายเปิดร้านใหม่ต้องรอผู้ดูแลระบบอนุมัติ
      status: role == UserRole.seller ? 'pending' : 'active',
    );
    _demoAccounts[email] = {'password': password, 'user': newUser};
    user = newUser;

    // ผู้ขายที่สมัคร -> สร้างคำขอให้ admin อนุมัติ
    if (role == UserRole.seller && shopName != null) {
      requests = [
        MarketRequest(
          id: 'r-${DateTime.now().millisecondsSinceEpoch}',
          type: RequestType.sellerApply,
          title: shopName,
          subtitle: 'สมัครเปิดร้าน · ${shopCategory ?? "ทั่วไป"}',
          amount: '฿1,500/เดือน',
          requesterName: name,
        ),
        ...requests,
      ];
    }
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    if (_fb != null) await _fb.signOut();
    user = null;
    notifyListeners();
  }

  // ---------------- APPROVALS ----------------

  Future<void> setRequestStatus(String id, String status) async {
    if (_fb != null) {
      await _fb.setRequestStatus(id, status);
      requests = await _fb.fetchRequests();
    } else {
      requests = requests.map((r) {
        if (r.id != id) return r;
        return MarketRequest(
          id: r.id, type: r.type, title: r.title, subtitle: r.subtitle,
          amount: r.amount, requesterName: r.requesterName, status: status,
        );
      }).toList();
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

  // ---------------- BOOKING ----------------

  Future<void> bookStall(String stallId, String shopName) async {
    if (_fb != null) {
      await _fb.addBooking(stallId, shopName, user?.name ?? '');
    }
    // เพิ่มคำขอจองให้ admin อนุมัติ
    requests = [
      MarketRequest(
        id: 'r-${DateTime.now().millisecondsSinceEpoch}',
        type: RequestType.booking,
        title: shopName.isEmpty ? (user?.name ?? 'ผู้ขาย') : shopName,
        subtitle: 'ขอจองแผง $stallId',
        amount: '฿150/วัน',
        requesterName: user?.name ?? '',
      ),
      ...requests,
    ];
    notifyListeners();
  }
}

/// shortcut
final appState = AppState.instance;
