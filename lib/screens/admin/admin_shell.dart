import 'package:flutter/material.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/animations.dart';
import '../../widgets/market_map.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/change_password.dart';
import '../../theme/theme_controller.dart';
import '../profile_tab.dart';
import 'approvals_tab.dart';
import 'stalls_screen.dart';
import 'standard_tab.dart';
import 'users_screen.dart';
import 'banners_screen.dart';
import 'reviews_moderation_screen.dart';
import 'sales_report_screen.dart';

class AdminShell extends StatefulWidget {
  AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // ถูกส่งมาจากที่อื่น เช่น เพิ่งยื่นขอเปิดร้านแล้วต้องมาอนุมัติต่อ
    final want = appState.pendingAdminTab;
    if (want != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appState.pendingAdminTab = null;
        if (want != _tab) setState(() => _tab = want);
      });
    }
    final titles = ['แดชบอร์ดผู้ดูแลระบบ', 'อนุมัติคำขอ', 'แผนผังตลาด', 'ตรวจมาตรฐานร้าน', 'โปรไฟล์'];
    return FloatingNavScaffold(
      // หน้าฝั่งแอดมินยังเป็น list ธรรมดา จึงให้แถบเมนูกินพื้นที่ล่างตามปกติ
      floatOverContent: false,
      body: Scaffold(
        appBar: AppBar(
        title: Text(titles[_tab]),
        automaticallyImplyLeading: false,
        actions: [
          // ป้ายจำนวนคำขอค้าง
          ListenableBuilder(
            listenable: appState,
            builder: (_, __) {
              final n = appState.pendingCount;
              if (n == 0) return SizedBox(width: 8);
              return Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text('$n รอตรวจ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ),
                ),
              );
            },
          ),
          const ThemeToggleButton(),
          NotificationButton(),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (_, __) {
            switch (_tab) {
              case 1:
                return ApprovalsTab();
              case 2:
                return _AdminMap();
              case 3:
                return StandardTab();
              case 4:
                return ProfileTab();
              default:
                return _AdminDashboard(onGoApprovals: () => setState(() => _tab = 1));
            }
          },
        ),
      ),
      // ป้ายจำนวนคำขอค้างบนแท็บ "อนุมัติ" ต้องอัปเดตตามสถานะ จึงต้องฟัง appState
      navBar: ListenableBuilder(
        listenable: appState,
        builder: (_, __) => FloatingNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: [
          const NavItem(Icons.dashboard_outlined, 'หน้าหลัก', activeIcon: Icons.dashboard_rounded),
          NavItem(Icons.inbox_outlined, 'อนุมัติ',
              activeIcon: Icons.inbox_rounded, badge: appState.pendingCount),
          const NavItem(Icons.map_outlined, 'แผนผัง', activeIcon: Icons.map_rounded),
          const NavItem(Icons.verified_outlined, 'มาตรฐาน', activeIcon: Icons.verified_rounded),
          // ต้องมีโปรไฟล์ในฝั่งแอดมินด้วย ไม่งั้นเจ้าของตลาดที่เป็นแม่ค้าด้วย
          // จะไม่มีที่สลับบทบาท
          const NavItem(Icons.person_outline_rounded, 'โปรไฟล์', activeIcon: Icons.person_rounded),
        ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ออกจากระบบ'),
        content: Text('ต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok == true) await appState.signOut();
  }
}

// ---------------- DASHBOARD ----------------
class _AdminDashboard extends StatelessWidget {
  final VoidCallback onGoApprovals;
  const _AdminDashboard({required this.onGoApprovals});

  @override
  Widget build(BuildContext context) {
    final pending = appState.pendingCount;
    return ListView(
      padding: EdgeInsets.all(16),
      children: staggered([
        // งานที่แอดมินต้องลงมือทำ คือเรื่องเดียวที่สำคัญที่สุดของหน้านี้
        HeroPanel(
          icon: Icons.pending_actions_rounded,
          label: 'คำขอรอตรวจสอบ',
          value: '$pending',
          caption: pending == 0
              ? 'ไม่มีคำขอค้างอยู่'
              : 'จองแผงใหม่ ${appState.newBookingCount} · สมัครเปิดร้าน ${pending - appState.newBookingCount}',
          actions: [
            HeroAction(
              icon: Icons.inbox_rounded,
              label: pending == 0 ? 'เปิดกล่องคำขอ' : 'ตรวจคำขอทั้งหมด',
              filled: true,
              onTap: onGoApprovals,
            ),
          ],
        ),
        SizedBox(height: 12),
        // ตัวเลขภาพรวมอยู่ในกรอบเดียว แทนตาราง KPI 2x2 ที่ทำให้ทุกค่าดูสำคัญเท่ากัน
        StatStrip(items: [
          StatItem(icon: Icons.storefront_rounded, label: 'ร้านทั้งหมด', countTo: appState.shopCount),
          StatItem(icon: Icons.people_alt_rounded, label: 'ผู้ขาย', countTo: appState.sellerCount),
          StatItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'ค่าเช่า/เดือน',
            countTo: appState.monthlyRent,
            format: money,
            color: AppColors.ok,
          ),
        ]),
        SectionTitle('สรุปคำขอทั้งหมด', icon: Icons.event_available_rounded),
        GroupedCard(children: [
          _summaryRow('จองใหม่ (รออนุมัติ)', '${appState.newBookingCount}', AppColors.primary),
          _summaryRow('อนุมัติแล้ว', '${appState.approvedCount}', AppColors.ok),
          _summaryRow('ปฏิเสธ', '${appState.rejectedCount}', AppColors.bad),
        ]),
        SectionTitle('คำขอรอการอนุมัติ', icon: Icons.check_circle_outline_rounded,
            trailing: TextButton(onPressed: onGoApprovals, child: Text('ดูทั้งหมด'))),
        if (pending == 0)
          EmptyState(
            icon: Icons.task_alt_rounded,
            message: 'ตรวจครบทุกคำขอแล้ว',
          )
        else
          ...appState.pendingRequests.take(3).map((r) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: RequestCard(request: r),
              )),
        SectionTitle('เครื่องมือ', icon: Icons.apps_rounded),
        // เครื่องมือเป็นรายการเรียงลง อ่านชื่อเต็มได้ ไม่ต้องย่อให้พอดีช่องสี่เหลี่ยม
        GroupedCard(
          rowPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          children: [
            _tool(context, Icons.manage_accounts_rounded, 'จัดการผู้ใช้',
                subtitle: 'ระงับ/เปิดใช้งาน และเปลี่ยนบทบาท',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UsersScreen()))),
            _tool(context, Icons.grid_view_rounded, 'จัดการแผง',
                subtitle: 'เพิ่ม/ลบแผง และตั้งราคาค่าเช่า',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const StallsScreen()))),
            _tool(context, Icons.view_carousel_rounded, 'จัดการแบนเนอร์',
                subtitle: 'รูปและข้อความโปรโมตบนหน้าแรก',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const BannersScreen()))),
            _tool(context, Icons.reviews_rounded, 'จัดการรีวิว',
                subtitle: 'ตรวจและลบรีวิวที่ไม่เหมาะสม',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ReviewsModerationScreen()))),
            _tool(context, Icons.bar_chart_rounded, 'รายงานยอดขาย',
                subtitle: 'ยอดขายรวมและอันดับร้านขายดี',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AdminSalesReportScreen()))),
            _tool(context, Icons.lock_reset_rounded, 'เปลี่ยนรหัสผ่าน',
                subtitle: 'รหัสผ่านบัญชีผู้ดูแลระบบ',
                onTap: () => showChangePasswordDialog(context)),
          ],
        ),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, Color c) => Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 16)),
      ]);

  Widget _tool(BuildContext context, IconData icon, String label,
          {String? subtitle, VoidCallback? onTap}) =>
      AppListRow(
        leading: IconChip(icon, color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
        title: label,
        subtitle: subtitle,
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        onTap: onTap ?? () => showSnack(context, '$label — อยู่ระหว่างพัฒนา'),
      );
}

// ---------------- MAP (read-only) ----------------
class _AdminMap extends StatefulWidget {
  const _AdminMap();

  @override
  State<_AdminMap> createState() => _AdminMapState();
}

class _AdminMapState extends State<_AdminMap> {
  Stall? _sel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        AppCard(
          child: MarketMap(
            stalls: appState.stalls,
            selectedId: _sel?.id,
            onTap: (s) => setState(() => _sel = s),
          ),
        ),
        if (_sel != null) ...[
          SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              IconChip(Icons.storefront_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผง ${_sel!.id}${_sel!.shopName != null ? " · ${_sel!.shopName}" : ""}',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('${_sel!.positionLabel} · ${_sel!.categoryLabel} · ฿${_sel!.pricePerDay}/วัน',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
