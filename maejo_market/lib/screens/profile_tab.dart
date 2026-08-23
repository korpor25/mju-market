import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/change_password.dart';
import 'favorites_screen.dart';

/// หน้าโปรไฟล์/บัญชี (ใช้ร่วมกันทุกบทบาท)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    if (u == null) return SizedBox();

    final items = <(IconData, String, VoidCallback?)>[
      (Icons.favorite_border_rounded, 'ร้านที่ติดตาม',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      (Icons.history_rounded, 'ประวัติการเข้าชม', null),
      (Icons.notifications_none_rounded, 'การแจ้งเตือน', null),
      (Icons.settings_outlined, 'ตั้งค่า', null),
      (Icons.help_outline_rounded, 'ช่วยเหลือ / ติดต่อเรา', null),
    ];

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(18)),
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(u.email, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      SizedBox(height: 6),
                      _roleBadge(u),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
        // ผู้ใช้ที่มีหลายบทบาท (เช่น เจ้าของตลาดที่เป็นแม่ค้าด้วย)
        // สลับมุมมองได้โดยไม่ต้องออกจากระบบ — เปลี่ยนแค่มุมมอง ไม่ได้เพิ่ม/ลดสิทธิ์
        if (u.hasMultipleRoles) ...[
          SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('สลับบทบาท',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
                SizedBox(height: 4),
                Text('บัญชีนี้มีหลายบทบาท เลือกได้ว่าจะใช้งานในมุมมองไหน',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in (u.allRoles.toList()
                      ..sort((a, b) => b.rank.compareTo(a.rank))))
                      ChoiceChip(
                        selected: u.role == r,
                        label: Text(r.labelTh),
                        onSelected: (_) => appState.switchRole(r),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _menuItem(context, items[i].$1, items[i].$2, border: true, onTap: items[i].$3),
              _menuItem(context, Icons.lock_reset_rounded, 'เปลี่ยนรหัสผ่าน',
                  border: false, onTap: () => showChangePasswordDialog(context)),
              Divider(height: 1, color: AppColors.border),
              _menuItem(context, Icons.logout_rounded, 'ออกจากระบบ',
                  danger: true, border: false, onTap: () async {
                await appState.signOut();
              }),
            ],
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: Text('Maejo Market · v1.0.0', style: TextStyle(color: AppColors.faint, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _roleBadge(AppUser u) {
    final pending = u.role == UserRole.seller && u.isPending;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: pending ? AppColors.warnSoft : AppColors.leafSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        pending ? '${u.role.labelTh} · รออนุมัติ' : u.role.labelTh,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: pending ? AppColors.warn : AppColors.primary,
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      {bool danger = false, bool border = true, VoidCallback? onTap}) {
    final color = danger ? AppColors.bad : AppColors.primary;
    return InkWell(
      onTap: onTap ?? () => showSnack(context, '$label — อยู่ระหว่างพัฒนา'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: border ? Border(bottom: BorderSide(color: AppColors.border)) : null,
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: danger ? AppColors.badSoft : AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: danger ? AppColors.bad : AppColors.text)),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ]),
      ),
    );
  }
}
