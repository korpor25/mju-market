import '../../widgets/image_field.dart';
import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/shop.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ShopEditScreen extends StatefulWidget {
  final Shop shop;
  ShopEditScreen({super.key, required this.shop});

  @override
  State<ShopEditScreen> createState() => _ShopEditScreenState();
}

class _ShopEditScreenState extends State<ShopEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.shop.name);
  late final TextEditingController _desc = TextEditingController(text: widget.shop.description);
  late final TextEditingController _hours = TextEditingController(text: widget.shop.hours);
  late final TextEditingController _image = TextEditingController(text: widget.shop.imageUrl);
  late String? _category = _initialCategory();
  late bool _open = widget.shop.status != 'closed';
  bool _busy = false;

  String? _initialCategory() {
    return DemoData.categories.contains(widget.shop.category) ? widget.shop.category : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _hours, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await appState.updateShop({
      'name': _name.text.trim(),
      'category': _category ?? widget.shop.category,
      'description': _desc.text.trim(),
      'hours': _hours.text.trim(),
      'imageUrl': _image.text.trim(),
      'status': _open ? 'open' : 'closed',
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, bad: true);
    } else {
      showSnack(context, 'บันทึกข้อมูลร้านแล้ว');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แก้ไขข้อมูลร้าน')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // พรีวิวรูปร้าน
              Center(
                child: ListenableBuilder(
                  listenable: _image,
                  builder: (_, __) => NetImage(
                    url: _image.text.trim(),
                    fallback: widget.shop.icon,
                    width: 120, height: 120, radius: 20, iconSize: 54,
                  ),
                ),
              ),
              SizedBox(height: 18),
              _label('ชื่อร้าน'),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(prefixIcon: Icon(Icons.storefront_outlined), hintText: 'ชื่อร้าน'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่อร้าน' : null,
              ),
              SizedBox(height: 14),
              _label('ประเภทร้าน'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(prefixIcon: Icon(Icons.sell_outlined), hintText: 'เลือกประเภท'),
                items: DemoData.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              SizedBox(height: 14),
              _label('รายละเอียดร้าน'),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: InputDecoration(prefixIcon: Icon(Icons.notes_outlined), hintText: 'เล่าเกี่ยวกับร้านของคุณ (ไม่บังคับ)'),
              ),
              SizedBox(height: 14),
              _label('เวลาเปิด-ปิด'),
              TextFormField(
                controller: _hours,
                decoration: InputDecoration(prefixIcon: Icon(Icons.schedule_rounded), hintText: 'เช่น 06.00 - 14.00 น.'),
              ),
              SizedBox(height: 14),
              ImageField(
                controller: _image,
                label: 'รูปร้าน',
                hint: 'วางลิงก์รูป https://...',
                fallback: Icons.storefront_rounded,
                kind: 'shop',
              ),
              SizedBox(height: 14),
              AppCard(
                child: Row(children: [
                  Icon(_open ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: _open ? AppColors.ok : AppColors.muted),
                  SizedBox(width: 10),
                  Expanded(child: Text('เปิดร้าน (ให้ผู้ซื้อเห็นว่าเปิดขาย)', style: TextStyle(fontWeight: FontWeight.w600))),
                  Switch(value: _open, onChanged: (v) => setState(() => _open = v)),
                ]),
              ),
              SizedBox(height: 22),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                    : Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
      );
}
