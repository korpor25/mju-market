import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// ตรวจมาตรฐานร้านค้า (ให้คะแนนตามเกณฑ์)
class StandardTab extends StatefulWidget {
  const StandardTab({super.key});

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
  String _shop = 'ร้านป้าจันทร์ อาหารเหนือ';

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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // เลือกร้าน
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เลือกร้านที่จะตรวจ', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _shop,
                      isExpanded: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.storefront_outlined)),
                      items: shops
                          .map((s) => DropdownMenuItem(value: s.name, child: Text('${s.name} · ${s.stallId}')))
                          .toList(),
                      onChanged: (v) => setState(() => _shop = v ?? _shop),
                    ),
                  ],
                ),
              ),
              const SectionTitle('รายการตรวจ', icon: Icons.checklist_rounded),
              AppCard(
                child: Column(
                  children: _criteria.keys.map((k) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
                        _Stars(
                          value: _criteria[k]!,
                          onChanged: (v) => setState(() => _criteria[k] = v),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text('คะแนนเฉลี่ย', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_avg.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const Text(' / 5', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
              const SectionTitle('หมายเหตุเพิ่มเติม', icon: Icons.edit_note_rounded),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'บันทึกข้อสังเกต (ถ้ามี)…'),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                showSnack(context, 'บันทึกผลการตรวจ $_shop แล้ว (เฉลี่ย ${_avg.toStringAsFixed(1)})');
                _note.clear();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('บันทึกผลการตรวจ'),
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
            padding: const EdgeInsets.symmetric(horizontal: 1),
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
