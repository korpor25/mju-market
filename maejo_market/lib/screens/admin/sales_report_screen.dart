import 'package:flutter/material.dart';

import '../../models/sale.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animations.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/common.dart';

/// รายงานยอดขายภาพรวมทั้งตลาด (ฝั่งแอดมิน)
class AdminSalesReportScreen extends StatefulWidget {
  const AdminSalesReportScreen({super.key});

  @override
  State<AdminSalesReportScreen> createState() => _AdminSalesReportScreenState();
}

class _AdminSalesReportScreenState extends State<AdminSalesReportScreen> {
  SalePeriod _period = SalePeriod.week;
  List<Sale> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await appState.fetchAllSales();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลยอดขายไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานยอดขาย'),
        actions: [
          IconButton(tooltip: 'รีเฟรช', icon: Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildReport(),
    );
  }

  Widget _buildReport() {
    final scoped = SalesStats.filter(_all, _period);
    final stats = SalesStats(scoped);
    final chartDays = _period.chartDays;
    final daily = stats.daily(chartDays);
    final shopRows = stats.topShops();
    final productRows = stats.topProducts(limit: 8);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: staggered([
          PeriodSelector(value: _period, onChanged: (p) => setState(() => _period = p)),
          SizedBox(height: 14),
          HeroPanel(
            icon: Icons.payments_rounded,
            label: 'ยอดขายรวมทั้งตลาด · ${_period.labelTh}',
            value: money(stats.revenue),
            caption: stats.billCount == 0
                ? 'ยังไม่มีร้านบันทึกยอดขายในช่วงนี้'
                : '${stats.billCount} บิล จาก ${stats.shopCount} ร้าน',
          ),
          SizedBox(height: 12),
          StatStrip(items: [
            StatItem(icon: Icons.receipt_long_rounded, label: 'จำนวนบิล', countTo: stats.billCount),
            StatItem(icon: Icons.storefront_rounded, label: 'ร้านที่ขายได้', countTo: stats.shopCount),
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
          SectionTitle('อันดับร้านขายดี', icon: Icons.emoji_events_rounded),
          if (shopRows.isEmpty)
            EmptyState(
              icon: Icons.emoji_events_outlined,
              message: 'ยังไม่มีร้านที่บันทึกยอดขายในช่วง "${_period.labelTh}"',
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < shopRows.length; i++)
                    RankBarRow(
                      rank: i + 1,
                      label: shopRows[i].label,
                      subtitle: '${shopRows[i].qty} ชิ้น · '
                          '${(stats.revenue <= 0 ? 0 : shopRows[i].total / stats.revenue * 100).toStringAsFixed(1)}% ของตลาด',
                      trailing: money(shopRows[i].total),
                      ratio: shopRows.first.total <= 0 ? 0 : shopRows[i].total / shopRows.first.total,
                    ),
                ],
              ),
            ),
          SectionTitle('สินค้าขายดีรวมทุกร้าน', icon: Icons.local_fire_department_rounded),
          if (productRows.isEmpty)
            EmptyState(
              icon: Icons.local_fire_department_outlined,
              message: 'ยังไม่มีข้อมูลสินค้าในช่วงนี้',
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < productRows.length; i++)
                    RankBarRow(
                      rank: i + 1,
                      label: productRows[i].label,
                      subtitle: 'ขายได้ ${productRows[i].qty} ชิ้น',
                      trailing: money(productRows[i].total),
                      ratio: productRows.first.total <= 0
                          ? 0
                          : productRows[i].total / productRows.first.total,
                    ),
                ],
              ),
            ),
          SectionTitle('รายการขายล่าสุด', icon: Icons.history_rounded,
              trailing: Text('${scoped.length} รายการ',
                  style: TextStyle(fontSize: 12, color: AppColors.muted))),
          if (scoped.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'ยังไม่มีการบันทึกการขายในช่วงนี้',
            )
          else
            GroupedCard(
              children: [
                for (final s in scoped.take(20))
                  AppListRow(
                    leading: IconChip(Icons.sell_rounded,
                        color: AppColors.primary, bg: AppColors.leafSoft, size: 40),
                    title: '${s.productName} × ${s.qty}',
                    subtitle: s.shopName.isEmpty ? 'ไม่ระบุร้าน' : s.shopName,
                    note: s.createdAt == 0 ? null : thaiDateTime(s.date),
                    trailing: Text(money(s.total),
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
                  ),
              ],
            ),
          if (scoped.length > 20)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(
                child: Text('แสดง 20 รายการล่าสุดจากทั้งหมด ${scoped.length} รายการ',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: AppColors.bad),
            SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
