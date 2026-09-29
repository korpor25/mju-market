import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/change_password.dart';
import '../widgets/guest_gate.dart';
import '../widgets/notification_button.dart';
import '../widgets/shop_ui.dart';
import '../widgets/line_link.dart';
import 'favorites_screen.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// หน้าโปรไฟล์/บัญชี (ใช้ร่วมกันทุกบทบาท)
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    // ผู้เยี่ยมชมที่ยังไม่ลงทะเบียน — บอกว่าสมัครแล้วได้อะไรเพิ่ม แทนหน้าว่าง
    if (u == null) return const _GuestProfile();

    final items = <(IconData, String, VoidCallback)>[
      (Icons.favorite_border_rounded, 'ร้านที่ติดตาม',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      (Icons.history_rounded, 'ประวัติการเข้าชม',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
      (Icons.notifications_none_rounded, 'การแจ้งเตือน', () => openNotifications(context)),
      (Icons.settings_outlined, 'ตั้งค่า',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      (Icons.help_outline_rounded, 'ช่วยเหลือ / ติดต่อเรา',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
    ];

    return ListView(
      // เผื่อที่ให้แถบเมนูแคปซูลที่ลอยทับเนื้อหาอยู่ด้านล่าง
      padding: EdgeInsets.fromLTRB(16, 12, 16, navBarInset(context)),
      children: [
        PageHeading('บัญชีของฉัน'),
        SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(gradient: brandGradient, shape: BoxShape.circle),
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
        // แจ้งเตือนผ่าน LINE — ไม่แสดงในมุมมองแอดมิน เพราะแอดมินเป็นคนส่งแจ้งเตือน ไม่มีอะไรส่งหาแอดมิน
        // (บัญชีหลายบทบาทสลับไปมุมมองผู้ขาย/ผู้ซื้อแล้วเชื่อมได้ตามปกติ)
        if (AppConfig.lineReady && u.role != UserRole.admin) ...[
          SizedBox(height: 14),
          LineConnectCard(),
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

  /// ทุกเมนูต้องมีปลายทางจริง — onTap จึงบังคับใส่ ไม่มีทางหลุดเป็นเมนูหลอกอีก
  Widget _menuItem(BuildContext context, IconData icon, String label,
      {bool danger = false, bool border = true, required VoidCallback onTap}) {
    final color = danger ? AppColors.bad : AppColors.primary;
    return InkWell(
      onTap: onTap,
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

/// สีแบรนด์ LINE — ใช้กับปุ่มที่พาไปบัญชีทางการของตลาดเท่านั้น
const _lineGreen = Color(0xFF06C755);

/// หน้าบัญชีของผู้เยี่ยมชม — ไม่มีข้อมูลส่วนตัวให้แสดง
/// จึงบอกแทนว่าสมัครแล้วได้อะไรเพิ่ม และเปิดทางไปถาม LINE OA ได้เลยโดยไม่ต้องสมัคร
class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  static const _perks = [
    (Icons.favorite_border_rounded, 'ติดตามร้านโปรด', 'เก็บร้านที่ชอบไว้ กลับมาดูได้ทันที'),
    (Icons.rate_review_outlined, 'ให้คะแนนและรีวิว', 'บอกคนอื่นว่าร้านไหนของดี'),
    (Icons.notifications_none_rounded, 'รับแจ้งเตือน', 'ข่าวสารและโปรโมชั่นจากตลาด'),
    (Icons.storefront_outlined, 'เปิดร้านของตัวเอง', 'ยื่นขอเช่าแผงในตลาดได้จากในแอป'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, navBarInset(context)),
      children: [
        PageHeading('บัญชีของฉัน'),
        SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                  child: Icon(Icons.person_outline_rounded, color: AppColors.muted, size: 32),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้เยี่ยมชม',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('เข้าชมตลาดโดยไม่ต้องลงทะเบียน',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ]),
              SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => goToSignIn(context),
                    icon: Icon(Icons.login_rounded, size: 18),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text('เข้าสู่ระบบ')),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => goToSignIn(context),
                    icon: Icon(Icons.person_add_alt_rounded, size: 18),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text('สมัครสมาชิก')),
                  ),
                ),
              ]),
            ],
          ),
        ),
        SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สมัครสมาชิกแล้วทำอะไรได้เพิ่ม',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('ดูร้านค้า สินค้า ผังตลาด และโปรโมชั่น ทำได้อยู่แล้วโดยไม่ต้องสมัคร',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              SizedBox(height: 12),
              for (final p in _perks) _perkRow(p.$1, p.$2, p.$3),
            ],
          ),
        ),
        SizedBox(height: 14),
        // เมนูที่ไม่ต้องมีบัญชีก็ใช้ได้ (ประวัติเก็บอยู่ในเครื่อง)
        GroupedCard(
          children: [
            AppListRow(
              leading: IconChip(Icons.history_rounded,
                  color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
              title: 'ประวัติการเข้าชม',
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            AppListRow(
              leading: IconChip(Icons.settings_outlined,
                  color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
              title: 'ตั้งค่า',
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            AppListRow(
              leading: IconChip(Icons.help_outline_rounded,
                  color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
              title: 'ช่วยเหลือ / ติดต่อเรา',
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            ),
          ],
        ),
        // ถามข้อมูลตลาดผ่านไลน์ได้โดยไม่ต้องมีบัญชีในแอป
        if (AppConfig.lineReady) ...[
          SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: _lineGreen, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.chat_bubble_rounded, size: 17, color: Colors.white),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text('ถามข้อมูลตลาดทางไลน์',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
                SizedBox(height: 10),
                Text(
                  'ถามได้เลยว่ามีโปรโมชั่นอะไร แผงว่างกี่แผง หรือตลาดมีสินค้าที่ต้องการขายไหม '
                  'ไม่ต้องสมัครสมาชิก',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(AppConfig.lineAddFriendUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text('เพิ่มเพื่อนใน LINE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lineGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 20),
        Center(
          child: Text('Maejo Market · v1.0.0',
              style: TextStyle(color: AppColors.faint, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _perkRow(IconData icon, String title, String detail) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(detail, style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}
