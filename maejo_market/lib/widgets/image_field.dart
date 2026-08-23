import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// ช่องใส่รูปที่ใช้ร่วมกันทุกหน้า (ร้าน / สินค้า / แบนเนอร์)
///
/// อัปโหลดไฟล์จากเครื่องได้ถ้าตั้งค่า Cloudinary ไว้ใน [AppConfig]
/// ถ้ายังไม่ได้ตั้ง จะเหลือเฉพาะช่องวางลิงก์ — แอปยังใช้งานได้ปกติ
class ImageField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData fallback;
  final double previewHeight;

  /// โฟลเดอร์ปลายทางบน Cloudinary ใช้แค่ตั้งชื่อไฟล์ให้ดูออกว่ามาจากไหน
  final String kind;

  const ImageField({
    super.key,
    required this.controller,
    this.label = 'รูปภาพ',
    this.hint = 'วางลิงก์รูป (https://...)',
    this.fallback = Icons.image_outlined,
    this.previewHeight = 120,
    this.kind = 'image',
  });

  @override
  State<ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<ImageField> {
  bool _busy = false;
  String? _error;

  /// ลิงก์ที่เอาไปแสดง preview จริง — ตามหลังช่องพิมพ์อยู่เล็กน้อย
  String _preview = '';
  Timer? _debounce;

  // ไฟล์ใหญ่กว่านี้ผู้ใช้ตลาดไม่ได้ต้องการจริง และทำให้หน้าเว็บโหลดช้า
  static const _maxBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _preview = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  /// หน่วงก่อนโหลด preview — ถ้าโหลดทุกตัวอักษรที่พิมพ์ จะยิงลิงก์ที่ยัง
  /// พิมพ์ไม่จบเป็นสิบ ๆ ครั้ง ได้ 404 รัวและเปลืองเน็ตเปล่า
  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _preview = widget.controller.text.trim());
    });
    // ปุ่มล้างรูปต้องขึ้น/หายตามที่พิมพ์ทันที ไม่ต้องรอ debounce
    setState(() {});
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _busy = false);
        return; // ผู้ใช้กดยกเลิก ไม่ถือว่าผิดพลาด
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxBytes) {
        setState(() {
          _busy = false;
          _error = 'ไฟล์ใหญ่เกิน 10MB — ย่อรูปก่อนแล้วลองใหม่';
        });
        return;
      }

      final url = await Cloudinary.upload(
        bytes,
        filename: '${widget.kind}_${picked.name}',
      );
      if (!mounted) return;
      widget.controller.text = url;
      _debounce?.cancel();
      setState(() {
        _preview = url; // อัปโหลดเสร็จแล้วรู้แน่ว่าลิงก์ใช้ได้ แสดงเลยไม่ต้องหน่วง
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.text)),
        const SizedBox(height: 8),
        Stack(
          children: [
            LayoutBuilder(
              builder: (context, c) => NetImage(
                url: _preview,
                fallback: widget.fallback,
                width: c.maxWidth,
                height: widget.previewHeight,
                radius: 14,
                iconSize: 40,
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (Cloudinary.isReady) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _pickAndUpload,
              icon: Icon(_busy ? Icons.hourglass_top_rounded : Icons.upload_rounded, size: 18),
              label: Text(_busy ? 'กำลังอัปโหลด...' : 'เลือกรูปจากเครื่อง'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: url.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ล้างรูป',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _busy ? null : () => widget.controller.clear(),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        if (_error != null)
          Text(_error!,
              style: TextStyle(fontSize: 11.5, color: AppColors.bad, fontWeight: FontWeight.w600))
        else
          Text(
            Cloudinary.isReady
                ? 'อัปโหลดจากเครื่องได้ หรือจะวางลิงก์รูปเองก็ได้'
                : 'ยังอัปโหลดไฟล์ไม่ได้ — ตั้งค่า Cloudinary ใน AppConfig ก่อน ระหว่างนี้ใช้ลิงก์รูปแทน',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
      ],
    );
  }
}
