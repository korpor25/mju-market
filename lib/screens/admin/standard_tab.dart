import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// ตรวจมาตรฐานร้านค้า — ให้คะแนนตามเกณฑ์แล้วบันทึกลงระบบจริง
/// (ผลตรวจเก็บใน collection `inspections` และแจ้งเจ้าของร้านให้รู้ผล)
class StandardTab extends StatefulWidget {
  StandardTab({super.key});

  @override
  State<StandardTab> createState() => _StandardTabState();
}

/// เกณฑ์การตรวจ — 0 = ยังไม่ให้คะแนน (ไม่ตั้งค่าเริ่มต้นไว้ล่วงหน้า
/// ไม่งั้นแอดมินกดบันทึกผ่าน ๆ ได้ทั้งที่ยังไม่ได้ตรวจจริง)
const _kCriteria = [
  'ความสะอาด',
  'ความเป็นระเบียบ',
  'การจัดวางสินค้า',
  'การบริการ',
  'การจัดการขยะ',
];

class _StandardTabState extends State<StandardTab> {
  final _scores = <String, int>{for (final c in _kCriteria) c: 0};
  final _note = TextEditingController();
  String? _shopId;
  bool _busy = false;

  late Future<List<Map<String, dynamic>>> _history = appState.fetchInspections();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _complete => _scores.values.every((v) => v >= 1);

  double get _avg =>
      _scores.values.fold<int>(0, (a, b) => a + b) / _scores.length;

  Future<void> _save(String shopId, String shopName) async {
    setState(() => _busy = true);
    final err = await appState.saveInspection(
      shopId: shopId,
      shopName: shopName,
      scores: _scores,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, bad: true);
      return;
    }
    showSnack(context, 'บันทึกผลการตรวจ $shopName แล้ว (เฉลี่ย ${_avg.toStringAsFixed(1)})');
    setState(() {
      for (final k in _scores.keys.toList()) {
        _scores[k] = 0;
      }
      _note.clear();
      _shopId = null;
      _history = appState.fetchInspections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shops = appState.shops;
    // ค่าที่เลือกไว้อาจไม่มีอยู่จริง (ร้านถูกลบไปแล้ว)
    // ถ้าไม่กันตรงนี้ DropdownButtonFormField จะ assert แตกทันทีที่ build
    final selectedId = shops.any((s) => s.id == _shopId) ? _shopId : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // เลือกร้าน
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เลือกร้านที่จะตรวจ', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.storefront_outlined),
                        hintText: shops.isEmpty ? 'ยังไม่มีร้านค้าในระบบ' : 'เลือกร้าน',
                      ),
                      items: shops
                          .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.hasStall ? '${s.name} · ${s.stallId}' : s.name)))
                          .toList(),
                      onChanged: shops.isEmpty ? null : (v) => setState(() => _shopId = v),
                    ),
                  ],
                ),
              ),
              SectionTitle('รายการตรวจ', icon: Icons.checklist_rounded),
              AppCard(
                child: Column(
                  children: _kCriteria.map((k) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LayoutBuilder(builder: (context, c) {
                        final label = Row(children: [
                          Text(k, style: TextStyle(fontWeight: FontWeight.w600)),
                          if (_scores[k] == 0) ...[
                            SizedBox(width: 6),
                            Text('(ยังไม่ให้คะแนน)',
                                style: TextStyle(fontSize: 11, color: AppColors.faint)),
                          ],
                        ]);
                        final stars = _Stars(
                          value: _scores[k]!,
                          onChanged: (v) => setState(() => _scores[k] = v),
                        );
                        // ดาว 5 ดวงกว้างราว 140px — ถ้าที่เหลือไม่พอให้ขึ้นบรรทัดใหม่
                        // และย่อให้พอดีเสมอ แทนที่จะปล่อยให้ Row ล้น
                        if (c.maxWidth < 260) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: stars,
                              ),
                            ],
                          );
                        }
                        return Row(children: [Expanded(child: label), stars]);
                      }),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 14),
              AppCard(
                child: Row(children: [
                  Icon(Icons.star_rounded, color: _complete ? AppColors.accent : AppColors.faint),
                  SizedBox(width: 8),
                  Text('คะแนนเฉลี่ย', style: TextStyle(fontWeight: FontWeight.w700)),
                  Spacer(),
                  Text(_complete ? _avg.toStringAsFixed(1) : '—',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _complete ? AppColors.primary : AppColors.faint)),
                  Text(' / 5', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
              SectionTitle('หมายเหตุเพิ่มเติม', icon: Icons.edit_note_rounded),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(hintText: 'บันทึกข้อสังเกต (ถ้ามี)…'),
              ),
              SectionTitle('ผลตรวจล่าสุด', icon: Icons.history_rounded),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _history,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return AppCard(
                      child: Text('โหลดผลตรวจไม่สำเร็จ: ${snap.error}',
                          style: TextStyle(color: AppColors.bad, fontSize: 12.5)),
                    );
                  }
                  final list = snap.data ?? const [];
                  if (list.isEmpty) {
                    return AppCard(
                      child: Text('ยังไม่มีผลการตรวจที่บันทึกไว้',
                          style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return Column(
                    children: [
                      for (final e in list.take(10))
                        Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: _historyRow(e),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: (selectedId == null || !_complete || _busy)
                  ? null
                  : () {
                      final shop = shops.firstWhere((s) => s.id == selectedId);
                      _save(shop.id, shop.name);
                    },
              icon: Icon(_busy ? Icons.hourglass_top_rounded : Icons.save_outlined),
              label: Text(_busy
                  ? 'กำลังบันทึก...'
                  : (selectedId == null
                      ? 'เลือกร้านก่อน'
                      : (_complete ? 'บันทึกผลการตรวจ' : 'ให้คะแนนให้ครบทุกข้อ'))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyRow(Map<String, dynamic> e) {
    final avg = (e['avg'] as num?)?.toDouble() ?? 0;
    final millis = (e['createdAt'] as int?) ?? 0;
    final when = millis == 0
        ? 'เพิ่งบันทึก'
        : _dateTh(DateTime.fromMillisecondsSinceEpoch(millis));
    final note = (e['note'] ?? '') as String;
    return AppCard(
      child: Row(children: [
        IconChip(Icons.fact_check_outlined, color: AppColors.primary, bg: AppColors.leafSoft),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${e['shopName'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Text('$when · ผู้ตรวจ ${e['byName'] ?? '-'}',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              if (note.trim().isNotEmpty)
                Text(note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        Text('${avg.toStringAsFixed(1)}/5',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
      ]),
    );
  }

  static String _dateTh(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    final time = '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} ${months[d.month - 1]} ${d.year + 543} · $time น.';
  }
}

class _Stars extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stars({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? AppColors.accent : AppColors.border,
              size: 26,
            ),
          ),
        );
      }),
    );
  }
}
