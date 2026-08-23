import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// ตรวจมาตรฐานร้านค้า (ให้คะแนนตามเกณฑ์)
class StandardTab extends StatefulWidget {
  StandardTab({super.key});

  @override
  State<StandardTab> createState() => _StandardTabState();
}

class _StandardTabState extends State<StandardTab> {
  final _criteria = <String, int>{
    'ความสะอาด': 3,
    'ความเป็นระเบียบ': 5,
    'การจัดวางสินค้า': 4,
    'การบริการ': 4,
    'การจัดการขยะ': 3,
  };
  final _note = TextEditingController();
  String? _shopId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double get _avg =>
      _criteria.values.fold(0, (a, b) => a + b) / _criteria.length;

  @override
  Widget build(BuildContext context) {
    final shops = appState.shops;
    // ค่าที่เลือกไว้อาจไม่มีอยู่จริง (ร้านถูกลบ / ข้อมูลมาจาก Firestore ไม่ใช่ demo)
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
                          .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} · ${s.stallId}')))
                          .toList(),
                      onChanged: shops.isEmpty ? null : (v) => setState(() => _shopId = v),
                    ),
                  ],
                ),
              ),
              SectionTitle('รายการตรวจ', icon: Icons.checklist_rounded),
              AppCard(
                child: Column(
                  children: _criteria.keys.map((k) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LayoutBuilder(builder: (context, c) {
                        final label = Text(k, style: TextStyle(fontWeight: FontWeight.w600));
                        final stars = _Stars(
                          value: _criteria[k]!,
                          onChanged: (v) => setState(() => _criteria[k] = v),
                        );
                        // ดาว 5 ดวงกว้างราว 140px — ถ้าที่เหลือไม่พอให้ขึ้นบรรทัดใหม่
                        // และย่อให้พอดีเสมอ แทนที่จะปล่อยให้ Row ล้น
                        if (c.maxWidth < 220) {
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
                  Icon(Icons.star_rounded, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('คะแนนเฉลี่ย', style: TextStyle(fontWeight: FontWeight.w700)),
                  Spacer(),
                  Text(_avg.toStringAsFixed(1),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text(' / 5', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
              SectionTitle('หมายเหตุเพิ่มเติม', icon: Icons.edit_note_rounded),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(hintText: 'บันทึกข้อสังเกต (ถ้ามี)…'),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: selectedId == null
                  ? null
                  : () {
                      final shop = shops.firstWhere((s) => s.id == selectedId);
                      showSnack(context,
                          'บันทึกผลการตรวจ ${shop.name} แล้ว (เฉลี่ย ${_avg.toStringAsFixed(1)})');
                      _note.clear();
                    },
              icon: Icon(Icons.save_outlined),
              label: Text('บันทึกผลการตรวจ'),
            ),
          ),
        ),
      ],
    );
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
