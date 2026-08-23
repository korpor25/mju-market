import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/sale.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animations.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';

/// รายงานยอดขายของร้านตัวเอง (ฝั่งผู้ขาย)
class SalesReportScreen extends StatefulWidget {
  /// true = ถูกใช้เป็นแท็บใน SellerShell (ไม่ต้องมี AppBar ของตัวเอง)
  final bool embedded;
  const SalesReportScreen({super.key, this.embedded = false});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  SalePeriod _period = SalePeriod.week;

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final all = appState.sales;
        final scoped = SalesStats.filter(all, _period);
        final stats = SalesStats(scoped);
        final chartDays = _period.chartDays;
        final daily = stats.daily(chartDays);
        final hasShop = appState.myShop != null;

        return RefreshIndicator(
          onRefresh: appState.refreshSales,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: staggered([
              PeriodSelector(value: _period, onChanged: (p) => setState(() => _period = p)),
              SizedBox(height: 14),
              HeroPanel(
                icon: Icons.payments_rounded,
                label: 'ยอดขาย · ${_period.labelTh}',
                value: money(stats.revenue),
                caption: stats.billCount == 0
                    ? 'ยังไม่มีการขายในช่วงนี้'
                    : '${stats.billCount} บิล · เฉลี่ย ${money(stats.avgPerBill)}/บิล',
              ),
              SizedBox(height: 12),
              StatStrip(items: [
                StatItem(icon: Icons.receipt_long_rounded, label: 'จำนวนบิล', countTo: stats.billCount),
                StatItem(
                    icon: Icons.shopping_basket_rounded,
                    label: 'ชิ้นที่ขายได้',
                    countTo: stats.itemCount),
                StatItem(
                  icon: Icons.trending_up_rounded,
                  label: 'เฉลี่ย/บิล',
                  countTo: stats.avgPerBill.round(),
                  format: money,
                  color: AppColors.ok,
                ),
              ]),
              SectionTitle('ยอดขายรายวัน ($chartDays วันล่าสุด)', icon: Icons.bar_chart_rounded),
              AppCard(
                child: MiniBarChart(
                  bars: [for (final d in daily) BarDatum(thaiShortDate(d.day), d.total)],
                  labelEvery: chartDays > 14 ? 5 : (chartDays > 7 ? 2 : 1),
                ),
              ),
              SectionTitle('สินค้าขายดี', icon: Icons.emoji_events_rounded),
              _TopProducts(stats: stats),
              SectionTitle('รายการขายล่าสุด', icon: Icons.history_rounded,
                  trailing: Text('${scoped.length} รายการ',
                      style: TextStyle(fontSize: 12, color: AppColors.muted))),
              if (!hasShop)
                EmptyState(
                  icon: Icons.hourglass_bottom_rounded,
                  message: 'ร้านของคุณกำลังรอผู้ดูแลระบบอนุมัติ\nเมื่ออนุมัติแล้วจึงบันทึกการขายได้',
                )
              else if (scoped.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'ยังไม่มีการขายในช่วง "${_period.labelTh}"',
                  action: ElevatedButton.icon(
                    onPressed: () => showRecordSaleSheet(context),
                    icon: Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text('บันทึกการขาย'),
                    style: ElevatedButton.styleFrom(minimumSize: Size(0, 44)),
                  ),
                )
              else
                GroupedCard(
                  children: [for (final s in scoped.take(30)) _saleRow(context, s)],
                ),
              if (scoped.length > 30)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Center(
                    child: Text('แสดง 30 รายการล่าสุดจากทั้งหมด ${scoped.length} รายการ',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                ),
            ]),
          ),
        );
      },
    );

    final fab = ListenableBuilder(
      listenable: appState,
      builder: (context, _) => FloatingActionButton.extended(
        onPressed: appState.myShop == null
            ? () => showSnack(context, 'รอผู้ดูแลระบบอนุมัติร้านก่อน', bad: true)
            : () => showRecordSaleSheet(context),
        icon: Icon(Icons.add_shopping_cart_rounded),
        label: Text('บันทึกการขาย'),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        floatingActionButton: fab,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานยอดขาย'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: Icon(Icons.refresh_rounded),
            onPressed: appState.refreshSales,
          ),
        ],
      ),
      body: body,
      floatingActionButton: fab,
    );
  }
}

class _TopProducts extends StatelessWidget {
  final SalesStats stats;
  const _TopProducts({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = stats.topProducts();
    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.emoji_events_outlined,
        message: 'ยังไม่มีข้อมูลสินค้าขายดีในช่วงนี้',
      );
    }
    final top = rows.first.total;
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            RankBarRow(
              rank: i + 1,
              label: rows[i].label,
              subtitle: 'ขายได้ ${rows[i].qty} ชิ้น',
              trailing: money(rows[i].total),
              ratio: top <= 0 ? 0 : rows[i].total / top,
            ),
        ],
      ),
    );
  }
}

/// หนึ่งแถวรายการขายใน [GroupedCard]
Widget _saleRow(BuildContext context, Sale sale) {
  return AppListRow(
    leading: IconChip(Icons.sell_rounded, color: AppColors.primary, bg: AppColors.leafSoft, size: 40),
    title: sale.productName,
    subtitle:
        '${money(sale.price)} × ${sale.qty} · ${sale.createdAt == 0 ? "เพิ่งบันทึก" : thaiDateTime(sale.date)}',
    note: sale.note.isEmpty ? null : sale.note,
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(money(sale.total),
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
      IconButton(
        tooltip: 'ลบรายการ',
        icon: Icon(Icons.delete_outline_rounded, color: AppColors.bad, size: 20),
        visualDensity: VisualDensity.compact,
        constraints: BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        onPressed: () => _confirmDeleteSale(context, sale),
      ),
    ]),
  );
}

Future<void> _confirmDeleteSale(BuildContext context, Sale sale) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('ลบรายการขาย'),
      content: Text('ลบ "${sale.productName}" (${money(sale.total)}) ออกจากรายงาน?'),
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
  if (ok == true) {
    await appState.deleteSale(sale.id);
    if (context.mounted) showSnack(context, 'ลบรายการขายแล้ว');
  }
}

// ---------------- บันทึกการขาย ----------------

/// เปิดชีตบันทึกการขาย (เรียกได้จากทั้งแดชบอร์ดและหน้ารายงาน)
Future<void> showRecordSaleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _RecordSaleSheet(),
  );
}

class _RecordSaleSheet extends StatefulWidget {
  const _RecordSaleSheet();

  @override
  State<_RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends State<_RecordSaleSheet> {
  Product? _product;
  final _priceC = TextEditingController();
  final _qtyC = TextEditingController(text: '1');
  final _noteC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final products = appState.products;
    if (products.isNotEmpty) _select(products.first);
    _priceC.addListener(_refresh);
    _qtyC.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  void _select(Product p) {
    _product = p;
    _priceC.text = p.price.toStringAsFixed(p.price == p.price.roundToDouble() ? 0 : 2);
  }

  @override
  void dispose() {
    _priceC.dispose();
    _qtyC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_priceC.text.trim()) ?? 0;
  int get _qty => int.tryParse(_qtyC.text.trim()) ?? 0;
  double get _total => _price * _qty;

  void _bumpQty(int delta) {
    final next = (_qty + delta).clamp(1, 9999);
    _qtyC.text = '$next';
  }

  Future<void> _save() async {
    final p = _product;
    if (p == null) return;
    if (_qty <= 0) {
      showSnack(context, 'กรุณาระบุจำนวนมากกว่า 0', bad: true);
      return;
    }
    setState(() => _saving = true);
    final err = await appState.recordSale(
      product: p,
      qty: _qty,
      unitPrice: _price,
      note: _noteC.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      showSnack(context, err, bad: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context, 'บันทึกการขาย ${p.name} × $_qty (${money(_total)}) แล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final products = appState.products;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(children: [
                IconChip(Icons.add_shopping_cart_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('บันทึกการขาย', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('เลือกสินค้าและจำนวนที่ขายได้',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ]),
              SizedBox(height: 18),
              if (products.isEmpty) ...[
                Text('ยังไม่มีสินค้าในร้าน — เพิ่มสินค้าก่อนจึงบันทึกการขายได้',
                    style: TextStyle(color: AppColors.muted)),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('ปิด'),
                  ),
                ),
              ] else ...[
                Text('สินค้า', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(height: 8),
                DropdownButtonFormField<Product>(
                  initialValue: _product,
                  isExpanded: true,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.inventory_2_outlined)),
                  items: [
                    for (final p in products)
                      DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p.name} · ${money(p.price)}${p.available ? "" : " (ปิดขาย)"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (p) => setState(() {
                    if (p != null) _select(p);
                  }),
                ),
                SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ราคา/หน่วย (บาท)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(height: 8),
                          TextField(
                            controller: _priceC,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(prefixIcon: Icon(Icons.attach_money_rounded)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('จำนวน', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(height: 8),
                          Row(children: [
                            _QtyButton(icon: Icons.remove_rounded, onTap: () => _bumpQty(-1)),
                            Expanded(
                              child: TextField(
                                controller: _qtyC,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                ),
                              ),
                            ),
                            _QtyButton(icon: Icons.add_rounded, onTap: () => _bumpQty(1)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _noteC,
                  decoration: InputDecoration(
                    hintText: 'หมายเหตุ (ไม่บังคับ)',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.leafSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(Icons.calculate_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text('ยอดรวม', style: TextStyle(fontWeight: FontWeight.w700))),
                    Text(money(_total),
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                  ]),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving || _product == null || _qty <= 0 ? null : _save,
                    icon: _saving
                        ? SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.check_rounded),
                    label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการขาย'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
