import 'package:flutter/material.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/market_map.dart';
import '../profile_tab.dart';

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [_SellerDashboard(), _ManageShop(), _BookSpace(), ProfileTab()];
    final titles = ['Dashboard ผู้ขาย', 'จัดการร้านค้า', 'จองพื้นที่ขาย', 'บัญชีของฉัน'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_tab]), automaticallyImplyLeading: false),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'หน้าหลัก'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'จัดการร้าน'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'จองพื้นที่'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'บัญชี'),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warnSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warn.withOpacity(0.4)),
      ),
      child: Row(children: const [
        Icon(Icons.hourglass_bottom_rounded, color: AppColors.warn),
        SizedBox(width: 12),
        Expanded(
          child: Text('ร้านของคุณกำลังรอผู้ดูแลระบบอนุมัติ — เมื่ออนุมัติแล้วจึงจะเปิดขายได้',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warn)),
        ),
      ]),
    );
  }
}

// ---------------- DASHBOARD ----------------
class _SellerDashboard extends StatelessWidget {
  const _SellerDashboard();

  @override
  Widget build(BuildContext context) {
    final u = appState.user!;
    final products = [
      ('ข้าวซอยไก่', '60 บาท', true),
      ('น้ำพริกหนุ่ม', '35 บาท', true),
      ('ไส้อั่ว', '40 บาท', false),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (u.isPending) const _PendingBanner(),
        AppCard(
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const Text('ร้านป้าจันทร์ อาหารเหนือ · โซน A แผง A-2',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: _MiniStat(label: 'ยอดเข้าชมวันนี้', value: '245')),
          SizedBox(width: 10),
          Expanded(child: _MiniStat(label: 'ยอดขายวันนี้', value: '฿3,250')),
          SizedBox(width: 10),
          Expanded(child: _MiniStat(label: 'คะแนนร้าน', value: '4.8')),
        ]),
        const SizedBox(height: 12),
        AppCard(
          child: Row(children: [
            const Icon(Icons.toggle_on_rounded, color: AppColors.ok),
            const SizedBox(width: 10),
            const Expanded(child: Text('สถานะร้าน', style: TextStyle(fontWeight: FontWeight.w700))),
            const StatusPill('เปิดขาย', tone: 'ok'),
          ]),
        ),
        SectionTitle('รายการสินค้าของฉัน', icon: Icons.inventory_2_outlined, trailing: TextButton.icon(
          onPressed: () => showSnack(context, 'เพิ่มสินค้าใหม่'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('เพิ่ม'),
        )),
        ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(p.$2, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  StatusPill(p.$3 ? 'พร้อมขาย' : 'หมด', tone: p.$3 ? 'ok' : 'bad'),
                ]),
              ),
            )),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      ]),
    );
  }
}

// ---------------- MANAGE SHOP ----------------
class _ManageShop extends StatelessWidget {
  const _ManageShop();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.info_outline_rounded, 'ข้อมูลร้านค้า'),
      (Icons.inventory_2_outlined, 'จัดการสินค้า'),
      (Icons.photo_library_outlined, 'รูปภาพร้าน'),
      (Icons.schedule_rounded, 'เวลาเปิด-ปิดร้าน'),
      (Icons.payments_outlined, 'ตั้งค่าการชำระเงิน'),
      (Icons.storefront_outlined, 'สถานะร้าน'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('🍲', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 12),
              const Text('ร้านป้าจันทร์ อาหารเหนือ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Text('โซน A แผง A-2', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                InkWell(
                  onTap: () => showSnack(context, '${items[i].$2} — อยู่ระหว่างพัฒนา'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      border: i != items.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(children: [
                      Icon(items[i].$1, color: AppColors.primary, size: 20),
                      const SizedBox(width: 14),
                      Expanded(child: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- BOOK SPACE ----------------
class _BookSpace extends StatefulWidget {
  const _BookSpace();

  @override
  State<_BookSpace> createState() => _BookSpaceState();
}

class _BookSpaceState extends State<_BookSpace> {
  Stall? _sel;

  Future<void> _confirm() async {
    if (_sel == null) return;
    await appState.bookStall(_sel!.id, appState.user?.name ?? '');
    if (!mounted) return;
    showSnack(context, 'ส่งคำขอจองแผง ${_sel!.id} แล้ว · รอผู้ดูแลระบบอนุมัติ');
    setState(() => _sel = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('เลือกแผงว่างที่ต้องการจอง',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 12),
              AppCard(
                child: MarketMap(
                  stalls: appState.stalls,
                  selectedId: _sel?.id,
                  onTap: (s) {
                    if (!s.isBookable) {
                      showSnack(context, 'แผง ${s.id} ไม่ว่าง — เลือกแผงสีเทา (ว่าง)', bad: true);
                      return;
                    }
                    setState(() => _sel = s);
                  },
                ),
              ),
              if (_sel != null) ...[
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        IconChip(Icons.check_circle_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('แผง ${_sel!.id} · โซน ${_sel!.zone}',
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              const Text('ขนาด 2x2 เมตร', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const Text('฿150/วัน', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ]),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _sel == null ? null : _confirm,
              icon: const Icon(Icons.send_rounded),
              label: Text(_sel == null ? 'เลือกแผงก่อน' : 'ส่งคำขอจองแผง ${_sel!.id}'),
            ),
          ),
        ),
      ],
    );
  }
}
