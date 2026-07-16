import 'package:flutter/material.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/market_map.dart';
import 'approvals_tab.dart';
import 'standard_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['แดชบอร์ดผู้ดูแลระบบ', 'อนุมัติคำขอ', 'แผนผังตลาด', 'ตรวจมาตรฐานร้าน'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        automaticallyImplyLeading: false,
        actions: [
          // ป้ายจำนวนคำขอค้าง
          ListenableBuilder(
            listenable: appState,
            builder: (_, __) {
              final n = appState.pendingCount;
              if (n == 0) return const SizedBox(width: 8);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                    child: Text('$n รอตรวจ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          switch (_tab) {
            case 1:
              return const ApprovalsTab();
            case 2:
              return const _AdminMap();
            case 3:
              return const StandardTab();
            default:
              return _AdminDashboard(onGoApprovals: () => setState(() => _tab = 1));
          }
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: appState,
        builder: (_, __) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'หน้าหลัก'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: appState.pendingCount > 0,
                label: Text('${appState.pendingCount}'),
                child: const Icon(Icons.inbox_outlined),
              ),
              label: 'อนุมัติ',
            ),
            const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'แผนผัง'),
            const NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'มาตรฐาน'),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            const KpiCard(icon: Icons.storefront_rounded, iconColor: AppColors.primary, iconBg: AppColors.leafSoft, label: 'ร้านทั้งหมด', value: '128', delta: '+6 เดือนนี้'),
            const KpiCard(icon: Icons.people_alt_rounded, iconColor: AppColors.primaryLight, iconBg: AppColors.leafSoft, label: 'ผู้ขายทั้งหมด', value: '96', delta: '+4 สัปดาห์นี้'),
            KpiCard(icon: Icons.pending_actions_rounded, iconColor: AppColors.accent, iconBg: AppColors.accentSoft, label: 'รอตรวจสอบ', value: '$pending', delta: null),
            const KpiCard(icon: Icons.account_balance_wallet_rounded, iconColor: AppColors.ok, iconBg: AppColors.okSoft, label: 'ค่าเช่า/เดือน', value: '฿221K', delta: '+8.4%'),
          ],
        ),
        const SectionTitle('การจองพื้นที่ (วันนี้)', icon: Icons.event_available_rounded),
        AppCard(
          child: Column(children: [
            _summaryRow('จองใหม่', '12', AppColors.primary),
            const Divider(color: AppColors.border, height: 18),
            _summaryRow('อนุมัติแล้ว', '8', AppColors.ok),
            const Divider(color: AppColors.border, height: 18),
            _summaryRow('ปฏิเสธ', '2', AppColors.bad),
          ]),
        ),
        SectionTitle('คำขอรอการอนุมัติ', icon: Icons.check_circle_outline_rounded,
            trailing: TextButton(onPressed: onGoApprovals, child: const Text('ดูทั้งหมด'))),
        if (pending == 0)
          const AppCard(child: Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('ไม่มีคำขอค้างอยู่ 🎉', style: TextStyle(color: AppColors.muted)),
          )))
        else
          ...appState.pendingRequests.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RequestCard(request: r),
              )),
        SectionTitle('เครื่องมือ', icon: Icons.apps_rounded),
        Row(children: [
          Expanded(child: _tool(context, Icons.fact_check_outlined, 'ตรวจร้านค้า')),
          const SizedBox(width: 10),
          Expanded(child: _tool(context, Icons.how_to_reg_outlined, 'อนุมัติการจอง')),
          const SizedBox(width: 10),
          Expanded(child: _tool(context, Icons.bar_chart_rounded, 'รายงาน')),
        ]),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color c) => Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 16)),
      ]);

  Widget _tool(BuildContext context, IconData icon, String label) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        onTap: () => showSnack(context, '$label — อยู่ระหว่างพัฒนา'),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
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
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: MarketMap(
            stalls: appState.stalls,
            selectedId: _sel?.id,
            onTap: (s) => setState(() => _sel = s),
          ),
        ),
        if (_sel != null) ...[
          const SizedBox(height: 14),
          AppCard(
            child: Row(children: [
              IconChip(Icons.storefront_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผง ${_sel!.id}${_sel!.shopName != null ? " · ${_sel!.shopName}" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(_sel!.isEmpty ? 'ยังไม่มีผู้เช่า' : 'โซน ${_sel!.zone} · ${_sel!.pricePerDay}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
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
