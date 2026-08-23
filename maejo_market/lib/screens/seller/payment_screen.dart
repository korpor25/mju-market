import 'package:flutter/material.dart';

import '../../app_config.dart';
import '../../models/shop.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/image_field.dart';

/// ชำระค่าเช่าแผง — ผู้ขายโอนเงินแล้วแนบสลิป แอดมินมายืนยันรับเงินทีหลัง
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _slip = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _slip.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(Shop shop, int amount) async {
    setState(() => _busy = true);
    final err = await appState.submitPayment(
      shop: shop,
      amount: amount,
      slipUrl: _slip.text.trim(),
      note: _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, bad: true);
      return;
    }
    _slip.clear();
    _note.clear();
    showSnack(context, 'แจ้งชำระเงินแล้ว รอผู้ดูแลระบบยืนยัน');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ค่าเช่าแผง')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          final shop = appState.myShop;
          if (shop == null) {
            return _empty(Icons.storefront_outlined, 'ยังไม่มีร้าน',
                'เปิดร้านและจองแผงก่อนจึงจะมีค่าเช่า');
          }
          if (!shop.hasStall) {
            return _empty(Icons.grid_view_rounded, 'ยังไม่ได้จองแผง',
                'ค่าเช่าคิดจากแผงที่เช่า — จองแผงก่อนแล้วค่อยกลับมา');
          }

          final amount = appState.monthlyFeeFor(shop);
          final due = appState.isPaymentDue(shop);
          final waiting = appState.hasPendingPayment(shop.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _billCard(shop, amount, due, waiting),
              const SizedBox(height: 14),
              if (waiting)
                _notice(Icons.hourglass_bottom_rounded, AppColors.warn, AppColors.warnSoft,
                    'แจ้งชำระแล้ว รอผู้ดูแลระบบยืนยันรับเงิน')
              else if (!due)
                _notice(Icons.check_circle_rounded, AppColors.ok, AppColors.okSoft,
                    'รอบนี้ชำระเรียบร้อยแล้ว')
              else ...[
                SectionTitle('ช่องทางชำระเงิน', icon: Icons.account_balance_rounded),
                _payInfo(),
                SectionTitle('แจ้งชำระเงิน', icon: Icons.receipt_long_rounded),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ImageField(
                        controller: _slip,
                        label: 'สลิปโอนเงิน',
                        hint: 'วางลิงก์สลิป หรืออัปโหลดจากเครื่อง',
                        fallback: Icons.receipt_long_rounded,
                        kind: 'slip',
                        previewHeight: 150,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(
                          hintText: 'หมายเหตุ เช่น เวลาโอน / เลขอ้างอิง (ไม่บังคับ)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : () => _submit(shop, amount),
                          icon: Icon(_busy ? Icons.hourglass_top_rounded : Icons.send_rounded),
                          label: Text(_busy ? 'กำลังส่ง...' : 'แจ้งชำระเงิน ฿${thousands(amount)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _billCard(Shop shop, int amount, bool due, bool waiting) {
    final perDay = amount ~/ AppConfig.billingDays;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconChip(Icons.receipt_long_rounded, color: AppColors.primary, bg: AppColors.leafSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('แผง ${shop.stallId} · โซน ${shop.zone}',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            StatusPill(
              waiting ? 'รอยืนยัน' : (due ? 'ค้างชำระ' : 'ชำระแล้ว'),
              tone: waiting ? 'warn' : (due ? 'bad' : 'ok'),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _line('ค่าเช่าแผงต่อวัน', '฿${thousands(perDay)}'),
                const SizedBox(height: 6),
                _line('จำนวนวันต่อรอบ', '${AppConfig.billingDays} วัน'),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('ยอดที่ต้องชำระ',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                    ),
                    Text('฿${thousands(amount)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          if (shop.lastPaidAt != null) ...[
            const SizedBox(height: 10),
            Text('ชำระล่าสุด ${_dateTh(shop.lastPaidAt!)}',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      );

  Widget _payInfo() {
    if (!AppConfig.payInfoReady) {
      return _notice(Icons.info_outline_rounded, AppColors.warn, AppColors.warnSoft,
          'ผู้ดูแลระบบยังไม่ได้ตั้งช่องทางรับเงิน — ติดต่อผู้ดูแลตลาดโดยตรงก่อน');
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (AppConfig.payPromptPay.isNotEmpty) _line('พร้อมเพย์', AppConfig.payPromptPay),
          if (AppConfig.payBankAccount.isNotEmpty) ...[
            const SizedBox(height: 6),
            _line('บัญชีธนาคาร', AppConfig.payBankAccount),
          ],
          if (AppConfig.payAccountName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _line('ชื่อบัญชี', AppConfig.payAccountName),
          ],
          const SizedBox(height: 10),
          Text('โอนแล้วแนบสลิปด้านล่าง ผู้ดูแลระบบจะตรวจและยืนยันให้',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _notice(IconData icon, Color fg, Color bg, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ),
        ]),
      );

  Widget _empty(IconData icon, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.faint),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      );

  static String _dateTh(DateTime d) =>
      '${d.day}/${d.month}/${d.year + 543}';
}
