import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// สีแบรนด์ LINE — ใช้เฉพาะกับส่วนที่เกี่ยวกับ LINE เท่านั้น
const _lineGreen = Color(0xFF06C755);

/// การ์ดในหน้าโปรไฟล์: สถานะการเชื่อมต่อ LINE + ปุ่มเชื่อม/ยกเลิก
class LineConnectCard extends StatelessWidget {
  const LineConnectCard({super.key});

  @override
  Widget build(BuildContext context) {
    final u = appState.user;
    if (u == null || !AppConfig.lineReady || u.role == UserRole.admin) {
      return const SizedBox.shrink();
    }

    final linked = u.lineLinked;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: linked ? _lineGreen : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chat_bubble_rounded,
                  size: 17, color: linked ? Colors.white : AppColors.muted),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('แจ้งเตือนผ่าน LINE',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    linked ? _linkedLabel(u.lineDisplayName) : 'ยังไม่ได้เชื่อม',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: linked ? _lineGreen : AppColors.muted,
                      fontWeight: linked ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            linked
                ? 'เรื่องร้าน แผง และค่าเช่า จะส่งเข้าไลน์ให้อัตโนมัติ'
                : 'รับแจ้งเตือนเรื่องร้าน แผง และค่าเช่า เข้าไลน์ ไม่ต้องคอยเปิดแอปเช็ค',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: linked
                ? OutlinedButton.icon(
                    onPressed: () => _confirmUnlink(context),
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('ยกเลิกการเชื่อมต่อ'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
                  )
                : ElevatedButton.icon(
                    onPressed: () => showLineLinkDialog(context),
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('เชื่อมต่อ LINE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lineGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _linkedLabel(String? displayName) {
    final name = displayName ?? '';
    return name.isEmpty ? 'เชื่อมแล้ว' : 'เชื่อมแล้ว · $name';
  }

  Future<void> _confirmUnlink(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ยกเลิกการเชื่อมต่อ?'),
        content: const Text(
            'จะไม่ได้รับแจ้งเตือนทางไลน์อีก แต่ยังเห็นแจ้งเตือนในแอปตามปกติ'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('ไม่ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.bad),
            child: const Text('ยกเลิกการเชื่อมต่อ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await appState.unlinkLine();
    if (context.mounted) showSnack(context, 'ยกเลิกการเชื่อมต่อ LINE แล้ว');
  }
}

/// ขั้นตอนผูกบัญชี: แอดเพื่อน OA -> พิมพ์รหัส 6 หลักในแชต -> กดยืนยัน
///
/// ทำไมต้องให้พิมพ์รหัสเอง: ฝั่งเซิร์ฟเวอร์รู้จักคนส่งจาก LINE userId ที่ติดมากับ
/// ข้อความเท่านั้น รหัสนี้คือสิ่งเดียวที่บอกว่า "ไลน์บัญชีนี้คือผู้ใช้คนไหนในแอป"
Future<void> showLineLinkDialog(BuildContext rootContext) async {
  await showDialog<void>(
    context: rootContext,
    builder: (dialogContext) => const _LineLinkDialog(),
  );
}

class _LineLinkDialog extends StatefulWidget {
  const _LineLinkDialog();

  @override
  State<_LineLinkDialog> createState() => _LineLinkDialogState();
}

class _LineLinkDialogState extends State<_LineLinkDialog> {
  String? _code;
  String? _error;
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final code = await appState.createLineLinkCode();
    if (!mounted) return;
    setState(() {
      _code = code;
      _loading = false;
      _error = code == null ? 'สร้างรหัสไม่สำเร็จ ลองปิดแล้วเปิดใหม่อีกครั้ง' : null;
    });
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    var linked = false;
    try {
      await appState.refreshUser();
      linked = appState.user?.lineLinked ?? false;
    } catch (_) {
      // เงียบไว้ — ถือว่ายังไม่เชื่อม แล้วให้ผู้ใช้กดใหม่ได้
    }
    if (!mounted) return;
    setState(() => _checking = false);

    if (linked) {
      Navigator.pop(context);
      showSnack(context, 'เชื่อมต่อ LINE สำเร็จ 🎉');
    } else {
      showSnack(context, 'ยังไม่พบการเชื่อมต่อ — ส่งรหัสในแชตแล้วลองอีกครั้ง', bad: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เชื่อมต่อ LINE'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _step(1, 'เพิ่มเพื่อนบัญชีทางการของตลาด'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(AppConfig.lineAddFriendUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('เพิ่มเพื่อนใน LINE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lineGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _step(2, 'พิมพ์รหัสนี้ส่งในแชตกับบัญชีทางการ'),
            const SizedBox(height: 8),
            _codeBox(),
            const SizedBox(height: 18),
            _step(3, 'กลับมากดปุ่มด้านล่างเพื่อยืนยัน'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        ElevatedButton(
          onPressed: (_checking || _code == null) ? null : _check,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                )
              : const Text('ส่งรหัสแล้ว'),
        ),
      ],
    );
  }

  Widget _step(int n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.leafSoft, shape: BoxShape.circle),
          child: Text('$n',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _codeBox() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
      );
    }

    final code = _code;
    if (code == null) {
      return Text(_error ?? 'สร้างรหัสไม่สำเร็จ',
          style: TextStyle(color: AppColors.bad, fontSize: 12.5));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'คัดลอก',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (mounted) showSnack(context, 'คัดลอกรหัสแล้ว');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('รหัสมีอายุ ${AppConfig.lineLinkCodeTtl.inMinutes} นาที',
            style: TextStyle(color: AppColors.faint, fontSize: 11.5)),
      ],
    );
  }
}
