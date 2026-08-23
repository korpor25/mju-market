import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/stall.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/market_map.dart';

/// จัดการแผงในตลาด — เพิ่ม / แก้ไข / ลบ และตั้งราคาค่าเช่ารายแผง
class StallsScreen extends StatefulWidget {
  const StallsScreen({super.key});

  @override
  State<StallsScreen> createState() => _StallsScreenState();
}

class _StallsScreenState extends State<StallsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการแผง')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มแผง'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          final all = [...appState.stalls]..sort((a, b) =>
              a.zone == b.zone ? a.number.compareTo(b.number) : a.zone.compareTo(b.zone));
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_off_rounded, size: 56, color: AppColors.faint),
                    const SizedBox(height: 12),
                    Text('ยังไม่มีแผงในตลาด',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text('กดปุ่มเพิ่มแผงเพื่อเริ่มสร้างผังตลาด',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            );
          }

          // จัดกลุ่มตามโซนเพื่อให้อ่านง่ายเวลามีหลายสิบแผง
          final byZone = <String, List<Stall>>{};
          for (final s in all) {
            byZone.putIfAbsent(s.zone, () => []).add(s);
          }
          final zones = byZone.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _summary(all),
              const SizedBox(height: 8),
              for (final z in zones) ...[
                SectionTitle('โซน $z', icon: Icons.grid_view_rounded),
                GroupedCard(
                  rowPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  children: [for (final s in byZone[z]!) _row(s)],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _summary(List<Stall> all) {
    final empty = all.where((s) => s.isEmpty).length;
    final rent = all.where((s) => !s.isEmpty).fold<int>(0, (a, s) => a + s.pricePerDay);
    return AppCard(
      child: Row(
        children: [
          _stat('${all.length}', 'แผงทั้งหมด'),
          _divider(),
          _stat('$empty', 'ว่าง'),
          _divider(),
          _stat('฿${thousands(rent)}', 'ค่าเช่า/วัน'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _row(Stall s) {
    return AppListRow(
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.isEmpty ? AppColors.surface2 : MarketMap.colorOf(s.status),
          borderRadius: BorderRadius.circular(12),
          border: s.isEmpty ? Border.all(color: AppColors.border) : null,
        ),
        child: Text(s.id,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: s.isEmpty ? AppColors.muted : Colors.white,
            )),
      ),
      title: '${s.id} · ${s.categoryLabel}',
      subtitle: '฿${thousands(s.pricePerDay)}/วัน',
      note: s.isEmpty ? null : (s.shopName ?? 'มีผู้เช่า'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 19),
          tooltip: 'แก้ไขแผง',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          onPressed: () => _edit(s),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: AppColors.bad, size: 20),
          tooltip: 'ลบแผง',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: EdgeInsets.zero,
          onPressed: () => _confirmDelete(s),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(Stall s) async {
    if (!s.isEmpty) {
      showSnack(context, 'ลบไม่ได้ — แผง ${s.id} มีผู้เช่าอยู่', bad: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบแผง'),
        content: Text('ลบแผง ${s.id} ออกจากผังตลาด?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ลบ', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final err = await appState.removeStall(s.id);
      if (mounted) showSnack(context, err ?? 'ลบแผง ${s.id} แล้ว', bad: err != null);
    }
  }

  Future<void> _edit(Stall? s) async {
    final isNew = s == null;
    final zones = appState.zones;
    final zoneC = TextEditingController(text: s?.zone ?? (zones.isNotEmpty ? zones.first : 'A'));
    final numC = TextEditingController(
        text: isNew ? '${appState.nextStallNumber(zoneC.text)}' : '${s.number}');
    final priceC = TextEditingController(text: '${s?.pricePerDay ?? 150}');
    String category = s?.category ?? '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, setSheet) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isNew ? 'เพิ่มแผง' : 'แก้ไขแผง ${s.id}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: zoneC,
                      enabled: isNew, // เปลี่ยนโซนของแผงเดิมไม่ได้ เพราะรหัสแผงคือ doc id
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          labelText: 'โซน', hintText: 'A', prefixIcon: Icon(Icons.map_outlined)),
                      onChanged: (v) {
                        if (isNew) {
                          numC.text = '${appState.nextStallNumber(v.trim().toUpperCase())}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: numC,
                      enabled: isNew,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'เลขแผง', prefixIcon: Icon(Icons.tag_rounded)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: DemoData.categories.contains(category) ? category : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sell_outlined),
                    hintText: 'หมวดสินค้าประจำแผง',
                  ),
                  items: DemoData.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSheet(() => category = v ?? ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ค่าเช่าต่อวัน (บาท)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      final zone = zoneC.text.trim().toUpperCase();
      final num = int.tryParse(numC.text.trim()) ?? 0;
      final price = int.tryParse(priceC.text.trim()) ?? 150;
      final id = isNew ? '$zone-$num' : s.id;

      String? err;
      if (zone.isEmpty || num <= 0) {
        err = 'กรอกโซนและเลขแผงให้ถูกต้อง';
      } else {
        err = await appState.saveStall(
          Stall(
            id: id,
            zone: zone,
            // แก้ไขแผงเดิมต้องคงสถานะและผู้เช่าไว้ ไม่งั้นร้านที่เช่าอยู่จะหลุด
            status: s?.status ?? 'empty',
            shopName: s?.shopName,
            category: category,
            pricePerDay: price,
          ),
          isNew: isNew,
        );
      }
      if (mounted) {
        showSnack(context, err ?? (isNew ? 'เพิ่มแผง $id แล้ว' : 'บันทึกแผง $id แล้ว'),
            bad: err != null);
      }
    }

    for (final c in [zoneC, numC, priceC]) {
      c.dispose();
    }
  }
}
