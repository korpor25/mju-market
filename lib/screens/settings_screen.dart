import 'package:flutter/material.dart';

import '../app_config.dart';
import '../models/app_user.dart';
import '../services/visit_history.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/change_password.dart';
import '../widgets/common.dart';
import '../widgets/line_link.dart';

/// ตั้งค่า — รวมสิ่งที่ผู้ใช้ปรับเองได้ไว้ที่เดียว
/// (เดิมกระจายอยู่ตามปุ่มบนหน้าจอ และเมนูนี้ขึ้นว่า "อยู่ระหว่างพัฒนา")
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ล้างประวัติการเข้าชม'),
        content: const Text('ลบรายการร้านที่เคยเข้าดูทั้งหมดใช่ไหม? (เก็บอยู่ในเครื่องนี้เท่านั้น)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: const Text('ล้างประวัติ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await VisitHistory.clear();
    if (mounted) showSnack(context, 'ล้างประวัติแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final u = appState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle('การแสดงผล', icon: Icons.palette_outlined),
          // ใช้แถวมาตรฐานของแอป ไม่ใช้ SwitchListTile เพราะ ListTile ในการ์ดที่มีพื้นสี
          // จะทำให้ ink splash มองไม่เห็น (Flutter เตือนเป็น assertion)
          ValueListenableBuilder<bool>(
            valueListenable: themeController,
            builder: (context, dark, _) => GroupedCard(
              children: [
                AppListRow(
                  leading: IconChip(
                    dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                    bg: AppColors.leafSoft,
                    size: 38,
                  ),
                  title: 'โหมดกลางคืน',
                  subtitle: dark ? 'กำลังใช้พื้นหลังสีเข้ม' : 'กำลังใช้พื้นหลังสีอ่อน',
                  trailing: Switch(value: dark, onChanged: (v) => setDarkMode(v)),
                  onTap: () => setDarkMode(!dark),
                ),
              ],
            ),
          ),

          // แจ้งเตือนทางไลน์ — ผู้เยี่ยมชมยังไม่มีบัญชีให้ผูก และแอดมินเป็นฝ่ายส่ง ไม่ใช่ฝ่ายรับ
          if (AppConfig.lineReady && u != null && u.role != UserRole.admin) ...[
            SectionTitle('การแจ้งเตือน', icon: Icons.notifications_none_rounded),
            const LineConnectCard(),
          ],

          SectionTitle('ข้อมูลในเครื่องนี้', icon: Icons.phone_iphone_rounded),
          GroupedCard(
            children: [
              AppListRow(
                leading: IconChip(Icons.history_rounded,
                    color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
                title: 'ล้างประวัติการเข้าชม',
                subtitle: 'ลบรายการร้านที่เคยเปิดดู',
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                onTap: _clearHistory,
              ),
            ],
          ),

          if (u != null) ...[
            SectionTitle('บัญชี', icon: Icons.lock_outline_rounded),
            GroupedCard(
              children: [
                AppListRow(
                  leading: IconChip(Icons.lock_reset_rounded,
                      color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
                  title: 'เปลี่ยนรหัสผ่าน',
                  subtitle: u.email,
                  trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                  onTap: () => showChangePasswordDialog(context),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          Center(
            child: Text('${AppConfig.appName} · v1.0.0',
                style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
