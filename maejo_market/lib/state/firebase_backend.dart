import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/shop.dart';
import '../models/market_request.dart';
import '../models/stall.dart';
import '../models/product.dart';
import '../models/promo_banner.dart';
import '../models/app_notification.dart';
import '../models/review.dart';
import '../models/sale.dart';

/// เลเยอร์เชื่อมต่อ Firebase (ใช้เมื่อ AppConfig.useFirebase = true)
class FirebaseBackend {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void watchAuth(Future<void> Function(AppUser?) onChange) {
    _auth.authStateChanges().listen((u) async {
      if (u == null) {
        await onChange(null);
        return;
      }
      final doc = await _db.collection('users').doc(u.uid).get();
      if (doc.exists) {
        await onChange(AppUser.fromMap(doc.data()!));
      } else {
        await onChange(AppUser(uid: u.uid, name: u.email ?? '', email: u.email ?? ''));
      }
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
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
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final uid = cred.user!.uid;
      final appUser = AppUser(
        uid: uid, name: name, email: email, phone: phone, role: role,
        status: role == UserRole.seller ? 'pending' : 'active',
      );
      await _db.collection('users').doc(uid).set(appUser.toMap());

      if (role == UserRole.seller && shopName != null) {
        // เก็บ metadata (uid/ชื่อร้าน/หมวด/เบอร์) ไว้ให้ตอน admin อนุมัติสร้างร้านได้
        await _db.collection('requests').add({
          'type': RequestType.sellerApply.id,
          'title': shopName,
          'subtitle': 'สมัครเปิดร้าน · ${shopCategory ?? "ทั่วไป"}',
          'amount': '฿1,500/เดือน',
          'requesterName': name,
          'status': 'pending',
          'uid': uid,
          'shopName': shopName,
          'shopCategory': shopCategory ?? 'ทั่วไป',
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'ไม่พบบัญชีอีเมลนี้';
      if (e.code == 'invalid-email') return 'รูปแบบอีเมลไม่ถูกต้อง';
      return 'ส่งอีเมลไม่สำเร็จ (${e.code})';
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }

  /// เปลี่ยนรหัสผ่านของผู้ใช้ปัจจุบัน (ยืนยันด้วยรหัสเดิมก่อน)
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) return 'ไม่พบผู้ใช้';
    try {
      final cred = EmailAuthProvider.credential(email: u.email!, password: currentPassword);
      await u.reauthenticateWithCredential(cred);
      await u.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') return 'รหัสผ่านปัจจุบันไม่ถูกต้อง';
      if (e.code == 'weak-password') return 'รหัสผ่านใหม่อ่อนเกินไป (อย่างน้อย 6 ตัว)';
      return 'เปลี่ยนรหัสผ่านไม่สำเร็จ (${e.code})';
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }

  // ---------------- READ ----------------

  Future<List<Shop>> fetchShops() async {
    final snap = await _db.collection('shops').get();
    return snap.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
  }

  Future<Shop?> fetchShop(String shopId) async {
    final d = await _db.collection('shops').doc(shopId).get();
    if (!d.exists) return null;
    return Shop.fromMap(d.id, d.data()!);
  }

  Future<List<MarketRequest>> fetchRequests() async {
    final snap = await _db.collection('requests').get();
    return snap.docs.map((d) => MarketRequest.fromMap(d.id, d.data())).toList();
  }

  Future<List<Stall>> fetchStalls() async {
    final snap = await _db.collection('stalls').get();
    return snap.docs.map((d) => Stall.fromMap(d.id, d.data())).toList();
  }

  /// สร้าง/แก้ไขแผง — id คือรหัสแผง (A-1) จึงใช้เป็น doc id ตรง ๆ
  Future<void> upsertStall(Stall s) async {
    await _db.collection('stalls').doc(s.id).set(s.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteStall(String id) async {
    await _db.collection('stalls').doc(id).delete();
  }

  /// จำนวนผู้ขายทั้งหมด (สำหรับ KPI แอดมิน)
  Future<int> fetchSellerCount() async {
    // นับทั้งเอกสารเก่า (role เดี่ยว) และเอกสารที่ migrate แล้ว (roles array)
    // ผู้ใช้ที่เป็น admin+seller จะถูกนับด้วย เพราะขายของในตลาดจริง
    final legacy = await _db.collection('users').where('role', isEqualTo: 'seller').get();
    final multi = await _db.collection('users').where('roles', arrayContains: 'seller').get();
    final ids = <String>{
      ...legacy.docs.map((d) => d.id),
      ...multi.docs.map((d) => d.id),
    };
    return ids.length;
  }

  // ---------------- USER MANAGEMENT (admin) ----------------

  /// อ่านข้อมูลผู้ใช้คนเดียว — ใช้รีเฟรชตัวเองหลังอนุมัติคำขอของตัวเอง
  Future<AppUser?> fetchUser(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? AppUser.fromMap(d.data()!) : null;
  }

  /// ผู้ใช้ที่ล็อกอินอยู่แล้วขอเปิดร้าน
  /// เดิมคำขอชนิดนี้สร้างได้เฉพาะตอนสมัครสมาชิก บัญชีเดิมจึงไม่มีทางเปิดร้านเลย
  /// ฟิลด์ต้องตรงกับที่ signUp เขียน ไม่งั้น approveRequest จะสร้างร้านไม่ได้
  Future<void> addSellerApply({
    required String uid,
    required String shopName,
    required String shopCategory,
    required String requesterName,
    String phone = '',
    String description = '',
  }) async {
    await _db.collection('requests').add({
      'type': RequestType.sellerApply.id,
      'title': shopName,
      'subtitle': 'สมัครเปิดร้าน · $shopCategory',
      'shopDescription': description,
      'amount': '฿1,500/เดือน',
      'requesterName': requesterName,
      'status': 'pending',
      'uid': uid,
      'shopName': shopName,
      'shopCategory': shopCategory,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AppUser>> fetchUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => AppUser.fromMap(d.data())).toList();
  }

  Future<void> setUserStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'status': status});
    if (status == 'suspended') {
      await _notify(uid, 'บัญชีถูกระงับ', 'บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ');
    } else if (status == 'active') {
      await _notify(uid, 'บัญชีเปิดใช้งานแล้ว', 'บัญชีของคุณกลับมาใช้งานได้ตามปกติ');
    }
  }

  /// ตั้งบทบาทเดี่ยว (แทนที่ของเดิมทั้งหมด)
  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'roles': [role],
      'activeRole': role,
    });
  }

  /// ให้/ถอนหลายบทบาท เช่น เจ้าของตลาดที่เป็นแม่ค้าด้วย = ['admin','seller']
  /// ฟิลด์ role เก็บบทบาทสิทธิ์สูงสุดไว้ให้ security rules และ query เดิมใช้ได้
  Future<void> setUserRoles(String uid, List<String> roles) async {
    if (roles.isEmpty) return;
    const rank = {'admin': 3, 'seller': 2, 'buyer': 1};
    final primary =
        roles.reduce((a, b) => (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b);
    final snap = await _db.collection('users').doc(uid).get();
    final active = snap.data()?['activeRole'] as String?;
    await _db.collection('users').doc(uid).update({
      'role': primary,
      'roles': roles,
      // ถ้าบทบาทที่ใช้อยู่ถูกถอนไป ให้ตกกลับไปที่บทบาทสูงสุด
      'activeRole': (active != null && roles.contains(active)) ? active : primary,
    });
  }

  /// บันทึกร้านที่ผู้ใช้เลือกจัดการอยู่ (สำหรับคนที่เปิดหลายร้าน)
  Future<void> setSelectedShop(String uid, String shopId) async {
    await _db.collection('users').doc(uid).update({'shopId': shopId});
  }

  /// บันทึกบทบาทที่ผู้ใช้เลือกใช้อยู่ (ไม่กระทบสิทธิ์)
  Future<void> setActiveRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'activeRole': role});
  }

  /// อัปเดตข้อมูลร้าน (ชื่อ/หมวด/รายละเอียด/เวลา/รูป/สถานะ)
  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    await _db.collection('shops').doc(shopId).set(data, SetOptions(merge: true));
  }

  // ---------------- PRODUCTS ----------------

  Future<List<Product>> fetchProducts(String shopId) async {
    final snap = await _db.collection('products').where('shopId', isEqualTo: shopId).get();
    return snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
  }

  Future<Product> addProduct(String shopId, String name, double price, {String imageUrl = ''}) async {
    final ref = await _db.collection('products').add({
      'shopId': shopId,
      'name': name,
      'price': price,
      'available': true,
      'imageUrl': imageUrl,
    });
    return Product(id: ref.id, shopId: shopId, name: name, price: price, imageUrl: imageUrl);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<void> setProductAvailable(String id, bool available) async {
    await _db.collection('products').doc(id).update({'available': available});
  }

  // ---------------- BANNERS (แบนเนอร์หน้าแรก — แอดมินจัดการ) ----------------

  /// ไม่ใช้ orderBy เพื่อเลี่ยง composite index — เรียงลำดับฝั่งแอปแทน
  Future<List<PromoBanner>> fetchBanners() async {
    final snap = await _db.collection('banners').get();
    return snap.docs.map((d) => PromoBanner.fromMap(d.id, d.data())).toList();
  }

  Future<String> addBanner(PromoBanner b) async {
    final ref = await _db.collection('banners').add(b.toMap());
    return ref.id;
  }

  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await _db.collection('banners').doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  // ---------------- SALES (ยอดขายที่ผู้ขายบันทึก) ----------------

  /// ยอดขายของร้านเดียว — ไม่ใช้ orderBy เพื่อเลี่ยง composite index
  Future<List<Sale>> fetchSales(String shopId) async {
    final snap = await _db.collection('sales').where('shopId', isEqualTo: shopId).get();
    final list = snap.docs.map((d) => Sale.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// ยอดขายทุกร้าน (รายงานภาพรวมของแอดมิน)
  Future<List<Sale>> fetchAllSales() async {
    final snap = await _db.collection('sales').get();
    final list = snap.docs.map((d) => Sale.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Sale> addSale(Sale sale) async {
    final ref = await _db.collection('sales').add({
      ...sale.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // คืนค่าพร้อมเวลาเครื่อง เพื่อให้ UI แสดงได้ทันทีก่อน serverTimestamp จะ resolve
    return Sale(
      id: ref.id,
      shopId: sale.shopId,
      shopName: sale.shopName,
      productId: sale.productId,
      productName: sale.productName,
      price: sale.price,
      qty: sale.qty,
      note: sale.note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> deleteSale(String id) async {
    await _db.collection('sales').doc(id).delete();
  }

  // ---------------- FAVORITES ----------------

  /// เพิ่ม/ลบร้านโปรดของผู้ใช้ (เก็บเป็น array บนเอกสาร users)
  Future<void> toggleFavorite(String uid, String shopId, bool add) async {
    await _db.collection('users').doc(uid).update({
      'favorites': add ? FieldValue.arrayUnion([shopId]) : FieldValue.arrayRemove([shopId]),
    });
  }

  // ---------------- REVIEWS ----------------

  Future<List<Review>> fetchReviews(String shopId) async {
    // ไม่ใช้ orderBy เพื่อเลี่ยง composite index — เรียงฝั่ง client แทน (แบบเดียวกับ notifications)
    final snap = await _db.collection('reviews').where('shopId', isEqualTo: shopId).get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// เพิ่ม/แก้รีวิว (1 รีวิวต่อผู้ใช้ต่อร้าน) แล้วคำนวณค่าเฉลี่ยกลับเข้า shop
  Future<void> addReview(String shopId, String uid, String authorName, int rating, String comment) async {
    final docId = '${shopId}_$uid';
    await _db.collection('reviews').doc(docId).set({
      'shopId': shopId,
      'uid': uid,
      'authorName': authorName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _recalcShopRating(shopId);
    // แจ้งเตือนเจ้าของร้าน (ถ้ามี)
    final shopDoc = await _db.collection('shops').doc(shopId).get();
    final ownerUid = shopDoc.data()?['ownerUid'] as String?;
    if (ownerUid != null && ownerUid != uid) {
      await _notify(ownerUid, 'มีรีวิวใหม่ ⭐',
          '$authorName ให้ $rating ดาวกับร้านของคุณ');
    }
  }

  Future<void> deleteReview(String reviewId, String shopId) async {
    await _db.collection('reviews').doc(reviewId).delete();
    await _recalcShopRating(shopId);
  }

  /// ดึงรีวิวทั้งหมด (สำหรับหน้า moderation ของแอดมิน)
  Future<List<Review>> fetchAllReviews() async {
    final snap = await _db.collection('reviews').get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// คำนวณค่าเฉลี่ยดาว + จำนวนรีวิว แล้วเขียนกลับเข้าเอกสารร้าน
  Future<void> _recalcShopRating(String shopId) async {
    final snap = await _db.collection('reviews').where('shopId', isEqualTo: shopId).get();
    final ratings = snap.docs.map((d) => ((d.data()['rating'] ?? 0) as num).toDouble()).toList();
    final count = ratings.length;
    final avg = count == 0 ? 0.0 : ratings.reduce((a, b) => a + b) / count;
    await _db.collection('shops').doc(shopId).set({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviews': count,
    }, SetOptions(merge: true));
  }

  // ---------------- NOTIFICATIONS ----------------

  Future<List<AppNotification>> fetchNotifications(String uid) async {
    // ไม่ใช้ orderBy เพื่อเลี่ยง composite index — เรียงฝั่ง client แทน
    final snap = await _db.collection('notifications').where('uid', isEqualTo: uid).get();
    final list = snap.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _notify(String? uid, String title, String body) async {
    if (uid == null || uid.isEmpty) return;
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- APPROVALS ----------------

  /// อนุมัติคำขอ — พร้อมทำงานตามชนิดคำขอจริง
  ///  - sellerApply : สร้างร้านเข้าแคตตาล็อก + ปลดล็อกผู้ขายเป็น active
  ///  - booking     : จัดแผงให้ร้าน (แผง occupied + ผูก stallId กับร้าน)
  Future<void> approveRequest(String id) async {
    final ref = _db.collection('requests').doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final type = data['type'] as String?;
    final uid = data['uid'] as String?;
    final title = (data['title'] ?? '') as String;

    if (type == RequestType.sellerApply.id) {
      if (uid != null) {
        // ร้านมีรหัสของตัวเอง ไม่ผูกกับ uid เจ้าของ — คนหนึ่งคนจึงเปิดได้หลายร้าน
        final shopRef = await _db.collection('shops').add({
          'name': data['shopName'] ?? data['title'] ?? 'ร้านค้า',
          'category': data['shopCategory'] ?? 'ทั่วไป',
          'ownerName': data['requesterName'] ?? '',
          'ownerUid': uid,
          'description': data['shopDescription'] ?? '',
          'stallId': '',
          'zone': '',
          'status': 'open',
          'payStatus': 'ok',
          'rating': 0,
          'reviews': 0,
        });
        // users.shopId = ร้านที่กำลังเลือกอยู่ ตั้งให้เฉพาะตอนยังไม่เคยมีร้าน
        // ไม่งั้นเปิดร้านที่สองแล้วจะสลับร้านที่เลือกไว้ให้โดยไม่ได้ตั้งใจ
        final me = await _db.collection('users').doc(uid).get();
        final current = (me.data()?['shopId'] ?? '') as String?;
        await _db.collection('users').doc(uid).update({
          'status': 'active',
          if (current == null || current.isEmpty) 'shopId': shopRef.id,
        });
        await _notify(uid, 'อนุมัติเปิดร้านแล้ว 🎉',
            'ร้าน "$title" ของคุณได้รับการอนุมัติแล้ว เริ่มเพิ่มสินค้าและจองแผงได้เลย');
      }
    } else if (type == RequestType.booking.id) {
      final stallId = data['stallId'] as String?;
      final shopName = (data['shopName'] ?? data['title']) as String?;
      final bookingShopId = (data['shopId'] ?? '') as String;
      if (stallId != null && stallId.isNotEmpty) {
        final zone = stallId.split('-').first;
        await _db.collection('stalls').doc(stallId).set({
          'zone': zone,
          'status': 'occupied',
          'shopName': shopName,
        }, SetOptions(merge: true));
        if (bookingShopId.isNotEmpty) {
          await _db.collection('shops').doc(bookingShopId).set({
            'stallId': stallId,
            'zone': zone,
          }, SetOptions(merge: true));
        }
        await _notify(uid, 'อนุมัติการจองแผงแล้ว ✅', 'คุณได้รับแผง $stallId เรียบร้อย');
      }
    } else if (type == RequestType.payment.id) {
      // ยืนยันรับเงินแล้วให้ร้านพ้นสถานะค้างชำระ และเริ่มนับรอบใหม่
      final payShopId = (data['shopId'] ?? '') as String;
      if (payShopId.isNotEmpty) {
        await _db.collection('shops').doc(payShopId).set({
          'payStatus': 'ok',
          'lastPaidAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
      await _notify(uid, 'ยืนยันรับชำระแล้ว ✅',
          'ตลาดได้รับค่าเช่า "$title" เรียบร้อยแล้ว');
    }

    await ref.update({'status': 'approved'});
  }

  Future<void> rejectRequest(String id) async {
    final ref = _db.collection('requests').doc(id);
    final snap = await ref.get();
    final data = snap.data();
    await ref.update({'status': 'rejected'});
    if (data != null) {
      await _notify(data['uid'] as String?, 'คำขอถูกปฏิเสธ',
          'คำขอ "${data['title'] ?? ''}" ไม่ผ่านการอนุมัติ กรุณาติดต่อผู้ดูแลระบบ');
    }
  }

  /// ใส่คอมม่าคั่นหลักพันให้ตรงกับที่อื่นในแอป
  /// (ใช้ตัวช่วยในนี้แทนของใน widgets เพราะชั้น backend ไม่ควรอิง Flutter)
  static String _baht(int v) {
    final s = v.toString();
    final out = StringBuffer('฿');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// ผู้ขายแจ้งชำระค่าเช่า — แอดมินมายืนยันรับเงินทีหลัง
  Future<void> addPayment({
    required String uid,
    required String shopId,
    required String shopName,
    required String stallId,
    required int amount,
    required String by,
    String slipUrl = '',
    String note = '',
  }) async {
    await _db.collection('requests').add({
      'type': RequestType.payment.id,
      'title': stallId.isEmpty ? shopName : '$shopName · $stallId',
      'subtitle': note.isEmpty ? 'แจ้งชำระค่าเช่าแผง' : note,
      'amount': _baht(amount),
      'requesterName': by,
      'status': 'pending',
      'uid': uid,
      'shopId': shopId,
      'slipUrl': slipUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBooking(
    String stallId,
    String shopName,
    String by, {
    required String uid,
    String shopId = '',
    int pricePerDay = 150,
  }) async {
    await _db.collection('requests').add({
      'type': RequestType.booking.id,
      'title': shopName.isEmpty ? by : shopName,
      'subtitle': 'ขอจองแผง $stallId',
      'amount': '${_baht(pricePerDay)}/วัน',
      'requesterName': by,
      'status': 'pending',
      'stallId': stallId,
      'shopName': shopName,
      'uid': uid,        // เจ้าของ — ใช้ส่งแจ้งเตือน
      'shopId': shopId,  // ร้านที่ขอจอง
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ไม่พบบัญชีนี้';
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้แล้ว';
      case 'weak-password':
        return 'รหัสผ่านอ่อนเกินไป (อย่างน้อย 6 ตัว)';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      default:
        return 'เข้าสู่ระบบไม่สำเร็จ (${e.code})';
    }
  }
}
