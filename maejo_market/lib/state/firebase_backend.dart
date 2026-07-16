import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/shop.dart';
import '../models/market_request.dart';
import '../models/stall.dart';

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
        await _db.collection('requests').add({
          'type': RequestType.sellerApply.id,
          'title': shopName,
          'subtitle': 'สมัครเปิดร้าน · ${shopCategory ?? "ทั่วไป"}',
          'amount': '฿1,500/เดือน',
          'requesterName': name,
          'status': 'pending',
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

  Future<List<Shop>> fetchShops() async {
    final snap = await _db.collection('shops').get();
    return snap.docs.map((d) => Shop.fromMap(d.id, d.data())).toList();
  }

  Future<List<MarketRequest>> fetchRequests() async {
    final snap = await _db.collection('requests').get();
    return snap.docs.map((d) => MarketRequest.fromMap(d.id, d.data())).toList();
  }

  Future<List<Stall>> fetchStalls() async {
    final snap = await _db.collection('stalls').get();
    return snap.docs
        .map((d) => Stall(
              id: d.id,
              zone: (d.data()['zone'] ?? '') as String,
              status: (d.data()['status'] ?? 'empty') as String,
              shopName: d.data()['shopName'] as String?,
            ))
        .toList();
  }

  Future<void> setRequestStatus(String id, String status) async {
    await _db.collection('requests').doc(id).update({'status': status});
  }

  Future<void> addBooking(String stallId, String shopName, String by) async {
    await _db.collection('requests').add({
      'type': RequestType.booking.id,
      'title': shopName,
      'subtitle': 'ขอจองแผง $stallId',
      'amount': '฿150/วัน',
      'requesterName': by,
      'status': 'pending',
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
