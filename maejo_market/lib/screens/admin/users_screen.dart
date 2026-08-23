import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/animations.dart';

class UsersScreen extends StatefulWidget {
  UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    appState.fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการผู้ใช้'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: Icon(Icons.refresh_rounded),
            onPressed: () => appState.fetchAllUsers(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final filters = [
            ('all', 'ทั้งหมด'),
            ('buyer', 'ผู้ซื้อ'),
            ('seller', 'ผู้ขาย'),
            ('admin', 'แอดมิน'),
          ];
          var users = appState.allUsers;
          if (_filter != 'all') {
            final want = UserRoleX.fromId(_filter);
            users = users.where((u) => u.can(want)).toList();
          }
          users.sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: filters.map((f) {
                    final on = f.$1 == _filter;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: on,
                        onSelected: (_) => setState(() => _filter = f.$1),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: on ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(child: Text('ไม่มีผู้ใช้', style: TextStyle(color: AppColors.muted)))
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10),
                        itemBuilder: (_, i) => FadeSlideIn(
                          delay: Duration(milliseconds: i * 45),
                          child: _UserRow(user: users[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final isSelf = appState.user?.uid == u.uid;
    final suspended = u.status == 'suspended';
    return AppCard(
      padding: EdgeInsets.all(12),
      onTap: isSelf ? null : () => _openActions(context, u),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(12)),
          child: Icon(_roleIcon(u.role), color: AppColors.primary, size: 22),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(u.name.isEmpty ? '(ไม่มีชื่อ)' : u.name, style: TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                if (isSelf) ...[
                  SizedBox(width: 6),
                  Text('(คุณ)', style: TextStyle(fontSize: 11, color: AppColors.faint)),
                ],
              ]),
              Text(u.email, style: TextStyle(fontSize: 12, color: AppColors.muted), overflow: TextOverflow.ellipsis),
              SizedBox(height: 5),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final r in (u.allRoles.toList()..sort((a, b) => b.rank.compareTo(a.rank))))
                  _tag(r.labelTh, AppColors.primary, AppColors.leafSoft),
                if (suspended)
                  _tag('ถูกระงับ', AppColors.bad, AppColors.badSoft)
                else if (u.isPending)
                  _tag('รออนุมัติ', AppColors.warn, AppColors.warnSoft)
                else
                  _tag('ใช้งาน', AppColors.ok, AppColors.okSoft),
              ]),
            ],
          ),
        ),
        if (!isSelf) Icon(Icons.chevron_right_rounded, color: AppColors.faint),
      ]),
    );
  }

  Future<void> _openActions(BuildContext context, AppUser u) async {
    final suspended = u.status == 'suspended';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text(u.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              ]),
            ),
            _action(
              sheetContext,
              suspended ? Icons.check_circle_outline_rounded : Icons.block_rounded,
              suspended ? 'เปิดใช้งานบัญชี' : 'ระงับบัญชี',
              danger: !suspended,
              onTap: () async {
                Navigator.pop(sheetContext);
                await appState.setUserStatus(u.uid, suspended ? 'active' : 'suspended');
                if (context.mounted) showSnack(context, suspended ? 'เปิดใช้งาน ${u.name} แล้ว' : 'ระงับ ${u.name} แล้ว', bad: !suspended);
              },
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('บทบาท (เลือกได้มากกว่าหนึ่ง)',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ),
            ),
            // แตะเพื่อเปิด/ปิดทีละบทบาท — ไม่ปิดชีต จะได้เลือกหลายอันรวดเดียว
            ListenableBuilder(
              listenable: appState,
              builder: (_, __) {
                final cur = appState.allUsers.firstWhere((x) => x.uid == u.uid, orElse: () => u);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in UserRole.values)
                      _action(
                        sheetContext,
                        _roleIcon(r),
                        r.labelTh,
                        selected: cur.can(r),
                        onTap: () async {
                          final next = cur.allRoles.toList();
                          if (next.contains(r)) {
                            if (next.length == 1) {
                              showSnack(context, 'ผู้ใช้ต้องมีอย่างน้อย 1 บทบาท', bad: true);
                              return;
                            }
                            next.remove(r);
                          } else {
                            next.add(r);
                          }
                          await appState.setUserRoles(cur.uid, next);
                          if (context.mounted) {
                            showSnack(context,
                                'บทบาทของ ${cur.name}: ${next.map((e) => e.labelTh).join(", ")}');
                          }
                        },
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, {bool danger = false, bool selected = false, required VoidCallback onTap}) {
    final color = danger ? AppColors.bad : (selected ? AppColors.primary : AppColors.text);
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.bad : AppColors.primary),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      trailing: selected ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }

  Widget _tag(String text, Color fg, Color bg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800)),
      );

  static IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.seller:
        return Icons.storefront_rounded;
      case UserRole.buyer:
        return Icons.person_rounded;
    }
  }
}
