import 'payment_screen.dart';
import '../../app_config.dart';
import '../../models/app_user.dart';
import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/product.dart';
import '../../models/shop.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/image_field.dart';
import '../../widgets/line_link.dart';
import '../../widgets/animations.dart';
import '../../widgets/market_map.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/shop_ui.dart';
import '../../theme/theme_controller.dart';
import '../profile_tab.dart';
import 'shop_edit_screen.dart';
import 'sales_report_screen.dart';

class SellerShell extends StatefulWidget {
  SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _tab = 0;
  bool _askedForShop = false;

  /// ให้หน้าลูกสั่งสลับแท็บได้ (เช่นเมนู "จัดการสินค้า" ที่พาไปรายการสินค้าในหน้าหลัก)
  void goToTab(int i) => setState(() => _tab = i);

  /// เพิ่งเข้ามาเป็นผู้ขายแต่ยังไม่มีร้านและไม่ได้ยื่นอะไรไว้
  /// เปิดหน้าขอเปิดร้านให้เลย จะได้ไม่ต้องมองหาปุ่มเอง (ถามครั้งเดียวพอ)
  void _maybeAskForShop() {
    if (_askedForShop) return;
    if (appState.myShops.isNotEmpty) return;
    if (appState.myPendingShopRequest != null) return;
    if (appState.user?.isPending == true) return;
    _askedForShop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showApplyForShopDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeAskForShop();
    final pages = const [
      _SellerDashboard(),
      _ManageShop(),
      SalesReportScreen(embedded: true),
      _BookSpace(),
      ProfileTab(),
    ];
    final titles = ['Dashboard ผู้ขาย', 'จัดการร้านค้า', 'รายงานยอดขาย', 'จองพื้นที่ขาย', 'บัญชีของฉัน'];
    return FloatingNavScaffold(
      // หน้าฝั่งผู้ขายยังเป็น list ธรรมดา จึงให้แถบเมนูกินพื้นที่ล่างตามปกติ
      floatOverContent: false,
      body: Scaffold(
        appBar: AppBar(
          title: Text(titles[_tab]),
          automaticallyImplyLeading: false,
          actions: const [ThemeToggleButton(), NotificationButton()],
        ),
        body: pages[_tab],
      ),
      navBar: FloatingNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        items: const [
          NavItem(Icons.dashboard_outlined, 'หน้าหลัก', activeIcon: Icons.dashboard_rounded),
          NavItem(Icons.storefront_outlined, 'จัดการร้าน', activeIcon: Icons.storefront_rounded),
          NavItem(Icons.bar_chart_outlined, 'ยอดขาย', activeIcon: Icons.bar_chart_rounded),
          NavItem(Icons.grid_view_outlined, 'จองพื้นที่', activeIcon: Icons.grid_view_rounded),
          NavItem(Icons.person_outline, 'บัญชี', activeIcon: Icons.person_rounded),
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
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warnSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warn.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
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
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final u = appState.user!;
        final Shop? shop = appState.myShop;
        final products = appState.products;
        // รออนุมัติ = มีคำขอเปิดร้านของตัวเองค้างอยู่ หรือบัญชียังไม่ถูกปลดล็อก
        // เดิมใช้ shop == null ซึ่งทำให้คนที่ไม่เคยยื่นขออะไรก็ขึ้นว่ารออนุมัติ
        final waiting = appState.myPendingShopRequest != null || u.isPending;
        return ListView(
          padding: EdgeInsets.all(16),
          children: staggered([
            if (waiting) const _PendingBanner(),
            // แถวประจำตัวร้าน — รวมสถานะร้านเข้ามาไว้ที่เดียว ไม่แยกเป็นการ์ดต่างหาก
            AppCard(
              child: AppListRow(
                leading: (shop != null && shop.hasImage)
                    ? NetImage(url: shop.imageUrl, fallback: shop.icon, width: 52, height: 52, radius: 15)
                    : Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(15)),
                        child: Icon(shop?.icon ?? Icons.storefront_rounded, color: Colors.white, size: 26),
                      ),
                title: shop?.name ?? (waiting ? 'ร้านกำลังรออนุมัติ' : 'ยังไม่มีร้าน'),
                subtitle: u.name,
                note: shop == null
                    ? null
                    : (shop.hasStall ? 'โซน ${shop.zone} · แผง ${shop.stallId}' : 'ยังไม่จองแผง'),
                trailing: StatusPill(
                  shop != null
                      ? (shop.status == 'open' ? 'เปิดขาย' : 'ปิด')
                      : (waiting ? 'รออนุมัติ' : 'ยังไม่มีร้าน'),
                  tone: shop != null
                      ? (shop.status == 'open' ? 'ok' : 'muted')
                      : (waiting ? 'warn' : 'muted'),
                ),
              ),
            ),
            // เปิดหลายร้านได้ — ให้เลือกว่ากำลังจัดการร้านไหนอยู่
            if (appState.myShops.length > 1) ...[
              SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in appState.myShops)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: s.id == shop?.id,
                          label: Text(s.name),
                          onSelected: (_) => appState.selectShop(s.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            // มีร้านแล้วก็ยังเปิดเพิ่มได้
            if (shop != null && !waiting)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showApplyForShopDialog(context),
                  icon: Icon(Icons.add_business_rounded, size: 18),
                  label: Text('เปิดร้านเพิ่ม'),
                ),
              ),
            // ไม่มีร้านและไม่ได้ยื่นอะไรไว้ — ต้องมีทางเปิดร้าน
            // (เดิมคำขอเปิดร้านสร้างได้เฉพาะตอนสมัครสมาชิก บัญชีเดิมจึงตันสนิท)
            if (shop == null && !waiting) ...[
              SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconChip(Icons.add_business_rounded,
                          color: AppColors.primary, bg: AppColors.leafSoft),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ยังไม่มีร้านในตลาด',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            Text('ยื่นขอเปิดร้านเพื่อเริ่มขายสินค้า',
                                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ]),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => showApplyForShopDialog(context),
                        icon: Icon(Icons.storefront_rounded),
                        label: Text('ขอเปิดร้าน'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ค่าเช่าแผง — เด้งให้เห็นตั้งแต่หน้าแรกถ้าค้างชำระ
            if (shop != null && shop.hasStall) ...[
              SizedBox(height: 12),
              AppCard(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                child: Row(children: [
                  IconChip(Icons.receipt_long_rounded,
                      color: AppColors.primary, bg: AppColors.leafSoft),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ค่าเช่าแผง', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('฿${thousands(appState.monthlyFeeFor(shop))} ต่อรอบ ${AppConfig.billingDays} วัน',
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  StatusPill(
                    appState.hasPendingPayment(shop.id)
                        ? 'รอยืนยัน'
                        : (appState.isPaymentDue(shop) ? 'ค้างชำระ' : 'ชำระแล้ว'),
                    tone: appState.hasPendingPayment(shop.id)
                        ? 'warn'
                        : (appState.isPaymentDue(shop) ? 'bad' : 'ok'),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ]),
              ),
            ],
            SizedBox(height: 12),
            // ค่าที่สำคัญที่สุดของหน้านี้ มีใบเดียว
            HeroPanel(
              icon: Icons.payments_rounded,
              label: 'ยอดขายวันนี้',
              value: money(appState.todayRevenue),
              caption: '${appState.todayBillCount} บิลวันนี้',
              actions: [
                HeroAction(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'บันทึกการขาย',
                  filled: true,
                  onTap: () => shop == null
                      ? showSnack(context, 'รอผู้ดูแลระบบอนุมัติร้านก่อน', bad: true)
                      : showRecordSaleSheet(context),
                ),
                HeroAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'ดูรายงาน',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SalesReportScreen())),
                ),
              ],
            ),
            SizedBox(height: 12),
            // ตัวเลขรองอยู่ในกรอบเดียวคั่นด้วยเส้น แทนการ์ดแยก 3 ใบ
            StatStrip(items: [
              StatItem(icon: Icons.inventory_2_outlined, label: 'สินค้า', countTo: products.length),
              StatItem(
                icon: Icons.star_rounded,
                label: 'คะแนนร้าน',
                value: (shop != null && shop.rating > 0) ? '${shop.rating}' : '—',
                color: AppColors.accent,
              ),
              StatItem(icon: Icons.reviews_outlined, label: 'รีวิว', countTo: shop?.reviews ?? 0),
            ]),
            SectionTitle('รายการสินค้าของฉัน', icon: Icons.inventory_2_outlined,
                trailing: TextButton.icon(
              onPressed: shop == null ? null : () => _productDialog(context),
              icon: Icon(Icons.add, size: 18),
              label: Text('เพิ่ม'),
            )),
            if (shop == null)
              EmptyState(
                icon: waiting ? Icons.hourglass_bottom_rounded : Icons.storefront_outlined,
                message: waiting
                    ? 'ร้านของคุณกำลังรอผู้ดูแลระบบอนุมัติ\nเมื่ออนุมัติแล้วจึงเพิ่มสินค้าได้'
                    : 'ยังไม่มีร้าน\nยื่นขอเปิดร้านก่อนจึงจะเพิ่มสินค้าได้',
              )
            else if (products.isEmpty)
              EmptyState(
                icon: Icons.add_box_outlined,
                message: 'ยังไม่มีสินค้าในร้าน',
                action: ElevatedButton.icon(
                  onPressed: () => _productDialog(context),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('เพิ่มสินค้าชิ้นแรก'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(0, 44)),
                ),
              )
            // สินค้าทั้งหมดอยู่ในกรอบเดียว คั่นด้วยเส้น แทนกรอบละชิ้น
            else
              GroupedCard(
                children: [for (final p in products) _productRow(context, p)],
              ),
          ]),
        );
      },
    );
  }

  /// ใช้ร่วมกันทั้งเพิ่มและแก้ไขสินค้า
  /// เดิมมีแต่เพิ่ม ถ้าใส่รูปหรือราคาผิดต้องลบแล้วสร้างใหม่
  Future<void> _productDialog(BuildContext context, {Product? existing}) async {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final priceC = TextEditingController(text: existing == null ? '' : _priceText(existing.price));
    final imageC = TextEditingController(text: existing?.imageUrl ?? '');
    final isNew = existing == null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isNew ? 'เพิ่มสินค้า' : 'แก้ไขสินค้า'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                      hintText: 'ชื่อสินค้า', prefixIcon: Icon(Icons.label_outline)),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: priceC,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      hintText: 'ราคา (บาท)', prefixIcon: Icon(Icons.attach_money_rounded)),
                ),
                SizedBox(height: 14),
                ImageField(
                  controller: imageC,
                  label: 'รูปสินค้า',
                  hint: 'วางลิงก์รูปสินค้า (ไม่บังคับ)',
                  fallback: Icons.restaurant_rounded,
                  previewHeight: 110,
                  kind: 'product',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ยกเลิก')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isNew ? 'เพิ่ม' : 'บันทึก')),
        ],
      ),
    );

    if (ok == true) {
      final name = nameC.text.trim();
      final price = double.tryParse(priceC.text.trim()) ?? 0;
      if (name.isNotEmpty) {
        final err = existing == null
            ? await appState.addProduct(name, price, imageUrl: imageC.text.trim())
            : await appState.editProduct(existing.id,
                name: name, price: price, imageUrl: imageC.text.trim());
        if (context.mounted && err != null) showSnack(context, err, bad: true);
      }
    }
    nameC.dispose();
    priceC.dispose();
    imageC.dispose();
  }

  /// ราคาเต็มบาทไม่ต้องโชว์ .00
  static String _priceText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// หนึ่งแถวสินค้าใน [GroupedCard] — สวิตช์เปิด/ปิดขายกับปุ่มลบย่อให้พอดีแถว
  Widget _productRow(BuildContext context, Product p) {
    return AppListRow(
      leading: NetImage(
          url: p.imageUrl, fallback: Icons.restaurant_rounded, width: 44, height: 44, radius: 12),
      title: p.name,
      subtitle: money(p.price),
      note: p.available ? null : 'ปิดขายอยู่',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: p.available,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => appState.toggleProduct(p.id, v),
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 19),
          tooltip: 'แก้ไขสินค้า',
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          onPressed: () => _productDialog(context, existing: p),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: AppColors.bad, size: 20),
          tooltip: 'ลบสินค้า',
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          onPressed: () => _confirmDelete(context, p),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ลบสินค้า'),
        content: Text('ลบ "${p.name}" ออกจากร้าน?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await appState.removeProduct(p.id);
  }
}

// ---------------- MANAGE SHOP ----------------
class _ManageShop extends StatelessWidget {
  const _ManageShop();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final Shop? shop = appState.myShop;
        final items = <(IconData, String)>[
          (Icons.info_outline_rounded, 'ข้อมูลร้านค้า'),
          (Icons.inventory_2_outlined, 'จัดการสินค้า'),
          (Icons.photo_library_outlined, 'รูปภาพร้าน'),
          (Icons.schedule_rounded, 'เวลาเปิด-ปิดร้าน'),
          (Icons.payments_outlined, 'ค่าเช่าแผงและแจ้งชำระ'),
          (Icons.storefront_outlined, 'สถานะร้าน'),
        ];
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (shop != null && shop.hasImage)
                      ? NetImage(url: shop.imageUrl, fallback: shop.icon, width: double.infinity, height: 120, radius: 14, iconSize: 52)
                      : Container(
                          height: 120,
                          decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Icon(shop?.icon ?? Icons.storefront_rounded, color: Colors.white, size: 52)),
                        ),
                  SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop?.name ?? 'ร้านของคุณ (รออนุมัติ)',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            shop == null
                                ? 'รอผู้ดูแลระบบอนุมัติ'
                                : (shop.hasStall ? 'โซน ${shop.zone} แผง ${shop.stallId}' : 'ยังไม่จองแผง · หมวด ${shop.category}'),
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if (shop != null)
                      OutlinedButton.icon(
                        onPressed: () => _openEdit(context, shop),
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text('แก้ไข'),
                        style: OutlinedButton.styleFrom(minimumSize: Size(84, 40), padding: EdgeInsets.symmetric(horizontal: 12)),
                      ),
                  ]),
                ],
              ),
            ),
            SizedBox(height: 14),
            GroupedCard(
              rowPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: [
                for (final item in items)
                  AppListRow(
                    leading: IconChip(item.$1,
                        color: AppColors.primary, bg: AppColors.leafSoft, size: 38),
                    title: item.$2,
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                    onTap: () {
                      if (shop == null) {
                        showSnack(context, 'รอผู้ดูแลระบบอนุมัติร้านก่อน', bad: true);
                        return;
                      }
                      const editable = {'ข้อมูลร้านค้า', 'รูปภาพร้าน', 'เวลาเปิด-ปิดร้าน', 'สถานะร้าน'};
                      if (editable.contains(item.$2)) {
                        _openEdit(context, shop);
                      } else if (item.$2 == 'จัดการสินค้า') {
                        // รายการสินค้าอยู่ในแท็บหน้าหลักอยู่แล้ว — พาไปที่เดิม ไม่ทำหน้าซ้ำ
                        context.findAncestorStateOfType<_SellerShellState>()?.goToTab(0);
                      } else {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
                      }
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openEdit(BuildContext context, Shop shop) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopEditScreen(shop: shop)));
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
    await appState.bookStall(_sel!.id, appState.myShop?.name ?? appState.user?.name ?? '');
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
            padding: EdgeInsets.all(16),
            children: [
              Text('เลือกแผงว่างที่ต้องการจอง',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 12),
              AppCard(
                child: MarketMap(
                  stalls: appState.stalls,
                  selectedId: _sel?.id,
                  // ค่าเช่าไม่เท่ากันทุกแผง ผู้ขายต้องเห็นราคาก่อนเลือก
                  showPrice: true,
                  // แผงไม่ว่างขึ้นกุญแจและกดไม่ได้เลย ไม่ต้องเด้งเตือนทีหลัง
                  canTap: (s) => s.isBookable,
                  onTap: (s) => setState(() => _sel = s),
                ),
              ),
              if (_sel != null) ...[
                SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        IconChip(Icons.check_circle_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('แผง ${_sel!.id} · ${_sel!.categoryLabel}',
                                  style: TextStyle(fontWeight: FontWeight.w800)),
                              Text('${_sel!.positionLabel} · ขนาด 2x2 เมตร',
                                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        Text('฿${_sel!.pricePerDay}/วัน',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
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
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _sel == null ? null : _confirm,
              icon: Icon(Icons.send_rounded),
              label: Text(_sel == null ? 'เลือกแผงก่อน' : 'ส่งคำขอจองแผง ${_sel!.id}'),
            ),
          ),
        ),
      ],
    );
  }
}

/// หัวข้อย่อยในฟอร์ม
Widget _formLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
    );

/// เปิดหน้าขอเปิดร้าน — ใช้ได้ทั้งจากปุ่มในหน้าผู้ขายและตอนเด้งอัตโนมัติจาก shell
/// ยื่นสำเร็จแล้วถ้าเป็นแอดมินด้วยจะพาไปหน้าอนุมัติต่อเลย (อนุมัติให้ตัวเองได้)
Future<void> showApplyForShopDialog(BuildContext context) async {
  final u = appState.user;
  final nameC = TextEditingController();
  final descC = TextEditingController();
  final ownerC = TextEditingController(text: u?.name ?? '');
  final phoneC = TextEditingController(text: u?.phone ?? '');
  String category = DemoData.categories.first;
  bool accepted = false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (_, setSheet) {
          // ต้องเชื่อม LINE ก่อน — ผลอนุมัติร้านแจ้งเข้าไลน์ ถ้ายื่นก่อนเชื่อม
          // แอดมินอาจอนุมัติไปแล้วแจ้งเตือนไม่ถึง (แอดมินอนุมัติให้ตัวเองได้ จึงยกเว้น)
          final me = appState.user;
          final needLine = AppConfig.lineReady && me != null && !me.can(UserRole.admin);
          final lineOk = !needLine || me.lineLinked;
          // ต้องกรอกครบและติ๊กยอมรับเงื่อนไขก่อนจึงส่งได้
          final ready = lineOk &&
              nameC.text.trim().isNotEmpty &&
              ownerC.text.trim().isNotEmpty &&
              phoneC.text.trim().isNotEmpty &&
              accepted;
          return Container(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                      color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(children: [
                    IconChip(Icons.add_business_rounded,
                        color: AppColors.primary, bg: AppColors.leafSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ขอเปิดร้านในตลาด',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('กรอกข้อมูลให้ครบ ผู้ดูแลตลาดจะตรวจก่อนอนุมัติ',
                              style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ]),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    children: [
                      if (needLine) ...[
                        _formLabel('เชื่อมต่อ LINE (ต้องทำก่อน)'),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: lineOk ? AppColors.leafSoft : AppColors.warnSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: (lineOk ? AppColors.primary : AppColors.warn)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(
                                    lineOk
                                        ? Icons.check_circle_rounded
                                        : Icons.chat_bubble_rounded,
                                    size: 20,
                                    color: lineOk ? AppColors.primary : AppColors.warn),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      lineOk ? 'เชื่อม LINE แล้ว' : 'ยังไม่ได้เชื่อม LINE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: lineOk ? AppColors.primary : AppColors.warn)),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                  lineOk
                                      ? 'ผลการอนุมัติร้านจะแจ้งเข้าไลน์ของคุณ'
                                      : 'ผลการอนุมัติร้านจะแจ้งเข้าไลน์ จึงต้องเชื่อมก่อนส่งคำขอ',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                              if (!lineOk) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await showLineLinkDialog(sheetContext);
                                      // หน้าต่างเชื่อมอัปเดต appState.user แล้ว วาดใหม่ให้ปลดล็อกปุ่มส่ง
                                      setSheet(() {});
                                    },
                                    icon: const Icon(Icons.add_link_rounded, size: 18),
                                    label: const Text('เชื่อมต่อ LINE'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      _formLabel('ข้อมูลร้าน'),
                      TextField(
                        controller: nameC,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setSheet(() {}),
                        decoration: const InputDecoration(
                          labelText: 'ชื่อร้าน *',
                          hintText: 'เช่น ร้านป้าจันทร์ อาหารเหนือ',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'หมวดสินค้า *',
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        items: DemoData.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setSheet(() => category = v ?? category),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descC,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียดร้าน',
                          hintText: 'ขายอะไร จุดเด่นของร้าน เวลาเปิด-ปิด (ไม่บังคับ)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _formLabel('ผู้ติดต่อ'),
                      TextField(
                        controller: ownerC,
                        onChanged: (_) => setSheet(() {}),
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ขอเปิดร้าน *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setSheet(() {}),
                        decoration: const InputDecoration(
                          labelText: 'เบอร์ติดต่อ *',
                          hintText: '08x-xxx-xxxx',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _formLabel('เงื่อนไขการเช่าแผง'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final t in AppConfig.shopTerms)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5, right: 8),
                                      child:
                                          Icon(Icons.circle, size: 6, color: AppColors.primary),
                                    ),
                                    Expanded(
                                      child: Text(t,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.5,
                                              color: AppColors.muted)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ListTile วาดเอฟเฟกต์กดลงบน Material ที่ใกล้ที่สุด แต่แผ่นฟอร์มเป็น
                      // Container ที่มีสีพื้น จึงบังเอฟเฟกต์ (Flutter เตือนเป็น error ทุกครั้งที่เปิด)
                      Material(
                        type: MaterialType.transparency,
                        child: CheckboxListTile(
                          value: accepted,
                          onChanged: (v) => setSheet(() => accepted = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text('ยอมรับเงื่อนไขการเช่าแผงข้างต้น',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          // ปิดปุ่มไว้จนกว่าจะกรอกครบและติ๊กยอมรับเงื่อนไข
                          onPressed: ready ? () => Navigator.pop(sheetContext, true) : null,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('ส่งคำขอ'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  if (ok == true) {
    final err = await appState.applyForShop(
      shopName: nameC.text,
      category: category,
      description: descC.text,
      ownerName: ownerC.text,
      phone: phoneC.text,
    );
    if (context.mounted) {
      showSnack(context, err ?? 'ส่งคำขอเปิดร้านแล้ว', bad: err != null);
    }
    // เจ้าของตลาดอนุมัติให้ตัวเองได้ พาไปหน้าอนุมัติต่อเลย ไม่ต้องไปหาเอง
    if (err == null && appState.user?.can(UserRole.admin) == true) {
      appState.requestAdminTab(1);
      await appState.switchRole(UserRole.admin);
    }
  }
  for (final c in [nameC, descC, ownerC, phoneC]) {
    c.dispose();
  }
}
