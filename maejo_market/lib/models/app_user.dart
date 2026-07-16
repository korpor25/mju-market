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
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// pending = รออนุมัติ (สำหรับผู้ขาย), active = ใช้งานได้
  final String status;
  final String? shopId;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.buyer,
    this.status = 'active',
    this.shopId,
  });

  bool get isPending => status == 'pending';

  AppUser copyWith({String? status, String? shopId, String? name, String? phone}) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.id,
        'status': status,
        'shopId': shopId,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: (m['uid'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        role: UserRoleX.fromId(m['role'] as String?),
        status: (m['status'] ?? 'active') as String,
        shopId: m['shopId'] as String?,
      );
}
