import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// หน้าโปรไฟล์/บัญชี (ใช้ร่วมกันทุกบทบาท)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    if (u == null) return const SizedBox();

    final items = <(IconData, String)>[
      (Icons.favorite_border_rounded, 'ร้านที่ติดตาม'),
      (Icons.history_rounded, 'ประวัติการเข้าชม'),
      (Icons.notifications_none_rounded, 'การแจ้งเตือน'),
      (Icons.settings_outlined, 'ตั้งค่า'),
      (Icons.help_outline_rounded, 'ช่วยเหลือ / ติดต่อเรา'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(u.email, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      _roleBadge(u),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _menuItem(context, items[i].$1, items[i].$2,
                    border: i != items.length - 1),
              const Divider(height: 1, color: AppColors.border),
              _menuItem(context, Icons.logout_rounded, 'ออกจากระบบ',
                  danger: true, border: false, onTap: () async {
                await appState.signOut();
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text('Maejo Market · v1.0.0', style: TextStyle(color: AppColors.faint, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _roleBadge(AppUser u) {
    final pending = u.role == UserRole.seller && u.isPending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: border ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
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
          const SizedBox(width: 13),
          Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: danger ? AppColors.bad : AppColors.text)),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ]),
      ),
    );
  }
}
