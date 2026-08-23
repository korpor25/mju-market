enum UserRole { buyer, seller, admin }

extension UserRoleX on UserRole {
  String get id => name;

  String get labelTh {
    switch (this) {
      case UserRole.buyer:
        return 'ผู้บริโภค';
      case UserRole.seller:
        return 'ผู้ขาย';
      case UserRole.admin:
        return 'ผู้ดูแลระบบ';
    }
  }

  /// ลำดับสิทธิ์ (มากกว่า = สูงกว่า) ใช้เลือก "บทบาทหลัก" ของผู้ใช้ที่มีหลายบทบาท
  int get rank {
    switch (this) {
      case UserRole.admin:
        return 3;
      case UserRole.seller:
        return 2;
      case UserRole.buyer:
        return 1;
    }
  }

  static UserRole fromId(String? v) {
    switch (v) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.buyer;
    }
  }

  /// อ่านรายการบทบาทจาก Firestore (ฟิลด์ roles) — คืนลิสต์ว่างถ้าไม่มีข้อมูล
  static List<UserRole> listFromIds(Object? v) {
    if (v is! List) return const [];
    final out = <UserRole>[];
    for (final e in v) {
      final r = fromId(e?.toString());
      if (!out.contains(r)) out.add(r);
    }
    return out;
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;

  /// บทบาทที่ "กำลังใช้งานอยู่" — เป็นตัวกำหนดหน้าจอที่ผู้ใช้เห็น
  final UserRole role;

  /// ทุกบทบาทที่ผู้ใช้มีสิทธิ์ (ว่าง = มีบทบาทเดียวตาม [role])
  /// เช่น เจ้าของตลาดที่เป็นแม่ค้าในตลาดด้วย = [admin, seller]
  final List<UserRole> roles;

  /// pending = รออนุมัติ (สำหรับผู้ขาย), active = ใช้งานได้
  final String status;
  final String? shopId;

  /// รหัสร้านที่ผู้ใช้ติดตาม (รายการโปรด)
  final List<String> favorites;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.buyer,
    this.roles = const [],
    this.status = 'active',
    this.shopId,
    this.favorites = const [],
  });

  bool get isPending => status == 'pending';

  /// บทบาททั้งหมดแบบใช้งานจริง — เผื่อเอกสารเก่าที่ยังไม่มีฟิลด์ roles
  List<UserRole> get allRoles => roles.isEmpty ? [role] : roles;

  bool get hasMultipleRoles => allRoles.length > 1;

  bool can(UserRole r) => allRoles.contains(r);

  /// บทบาทสิทธิ์สูงสุดที่มี — เขียนลงฟิลด์ role เดิมเพื่อให้ security rules
  /// และ query เก่าที่อ้าง role ยังทำงานได้
  UserRole get primaryRole => allRoles.reduce((a, b) => a.rank >= b.rank ? a : b);

  AppUser copyWith({
    String? status,
    String? shopId,
    String? name,
    String? phone,
    List<String>? favorites,
    UserRole? role,
    List<UserRole>? roles,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      favorites: favorites ?? this.favorites,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': primaryRole.id,
        'roles': allRoles.map((r) => r.id).toList(),
        'activeRole': role.id,
        'status': status,
        'shopId': shopId,
        'favorites': favorites,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) {
    final fromRoles = UserRoleX.listFromIds(m['roles']);
    final roles = fromRoles.isEmpty ? [UserRoleX.fromId(m['role'] as String?)] : fromRoles;

    // บทบาทที่เลือกใช้ล่าสุด — ถ้าไม่มีหรือไม่อยู่ในสิทธิ์ ให้ตกไปที่บทบาทสูงสุด
    var active = UserRoleX.fromId(m['activeRole'] as String?);
    if (m['activeRole'] == null || !roles.contains(active)) {
      active = roles.reduce((a, b) => a.rank >= b.rank ? a : b);
    }

    return AppUser(
      uid: (m['uid'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      role: active,
      roles: roles,
      status: (m['status'] ?? 'active') as String,
      shopId: m['shopId'] as String?,
      favorites: ((m['favorites'] ?? const []) as List).map((e) => e.toString()).toList(),
    );
  }
}
