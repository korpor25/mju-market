import 'package:flutter/material.dart';
import '../../models/market_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// การ์ดคำขอ + ปุ่มอนุมัติ/ปฏิเสธ (พร้อม dialog ยืนยัน)
class RequestCard extends StatelessWidget {
  final MarketRequest request;
  const RequestCard({super.key, required this.request});

  Future<void> _confirm(BuildContext context, {required bool approve}) async {
    final r = request;
    final isPay = r.isPayment;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(request: r, approve: approve),
    );
    if (ok != true) return;
    await appState.setRequestStatus(r.id, approve ? 'approved' : 'rejected');
    if (!context.mounted) return;
    showSnack(
      context,
      approve
          ? '${isPay ? "บันทึกการรับชำระ" : "อนุมัติ"} ${r.title} แล้ว'
          : 'ปฏิเสธคำขอ ${r.title} แล้ว',
      bad: !approve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AppCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(r.type.icon, color: r.type.color, bg: r.type.color.withOpacity(0.12), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: r.type.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(r.type.labelTh,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: r.type.color)),
                    ),
                    const SizedBox(height: 4),
                    Text(r.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(r.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(r.amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800), textAlign: TextAlign.right),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton(
              onPressed: () => _confirm(context, approve: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bad,
                side: const BorderSide(color: AppColors.badSoft),
                backgroundColor: AppColors.badSoft,
                minimumSize: const Size(52, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Icon(Icons.close_rounded, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirm(context, approve: true),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(r.isPayment ? 'ยืนยันรับเงิน' : 'อนุมัติ'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final MarketRequest request;
  final bool approve;
  const _ConfirmSheet({required this.request, required this.approve});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 14,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 38, height: 4, decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            IconChip(approve ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: approve ? AppColors.primary : AppColors.bad,
                bg: approve ? AppColors.leafSoft : AppColors.badSoft, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(approve ? (r.isPayment ? 'ยืนยันการรับชำระเงิน' : 'ยืนยันการอนุมัติ') : 'ยืนยันการปฏิเสธ',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const Text('ระบบจะบันทึกและแจ้งผลให้ผู้ขายทันที',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _row('ประเภท', r.type.labelTh),
              const SizedBox(height: 7),
              _row('รายการ', r.title),
              const SizedBox(height: 7),
              _row('รายละเอียด', r.subtitle),
              if (r.amount != '—') ...[
                const SizedBox(height: 7),
                _row(r.isPayment ? 'จำนวนเงิน' : 'ค่าใช้จ่าย', r.amount),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: approve ? AppColors.primary : AppColors.bad,
                ),
                child: Text(approve ? 'ยืนยัน' : 'ยืนยันปฏิเสธ'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      );
}

// ---------------- APPROVALS TAB ----------------
class ApprovalsTab extends StatelessWidget {
  const ApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = appState.pendingRequests;
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.ok, size: 52),
            SizedBox(height: 10),
            Text('ไม่มีคำขอค้างอยู่', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('ยืนยันครบทุกรายการแล้ว', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => _approveAll(context),
            icon: const Icon(Icons.done_all_rounded),
            label: Text('อนุมัติทั้งหมด (${pending.length})'),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (_, i) => RequestCard(request: pending[i]),
          ),
        ),
      ],
    );
  }

  Future<void> _approveAll(BuildContext context) async {
    final n = appState.pendingCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('อนุมัติทั้งหมด'),
        content: Text('ยืนยันดำเนินการทุกรายการที่ค้างอยู่ ($n รายการ) ในครั้งเดียว?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('อนุมัติทั้งหมด')),
        ],
      ),
    );
    if (ok != true) return;
    await appState.approveAll();
    if (!context.mounted) return;
    showSnack(context, 'ดำเนินการทุกรายการเรียบร้อย ($n รายการ)');
  }
}
