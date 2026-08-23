import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// ปุ่มกระดิ่ง + ป้ายจำนวนที่ยังไม่อ่าน → เปิดรายการแจ้งเตือน
class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final n = appState.unreadCount;
        return IconButton(
          tooltip: 'การแจ้งเตือน',
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text('$n'),
            child: Icon(Icons.notifications_none_rounded),
          ),
          onPressed: () => _open(context),
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    await appState.refreshNotifications();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotifSheet(),
    );
    // เปิดดูแล้ว = อ่านทั้งหมด
    await appState.markAllNotificationsRead();
  }
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final items = appState.notifications;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scroll) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Row(children: [
                    Icon(Icons.notifications_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('การแจ้งเตือน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined, color: AppColors.faint, size: 46),
                              SizedBox(height: 10),
                              Text('ยังไม่มีการแจ้งเตือน', style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scroll,
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemBuilder: (_, i) => _NotifTile(items[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification n;
  const _NotifTile(this.n);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.leafSoft, borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                  if (!n.read)
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                ]),
                if (n.body.isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(n.body, style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
                if (n.createdAt > 0) ...[
                  SizedBox(height: 5),
                  Text(_timeAgo(n.createdAt), style: TextStyle(fontSize: 11, color: AppColors.faint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(int millis) {
  final diff = DateTime.now().millisecondsSinceEpoch - millis;
  final m = diff ~/ 60000;
  if (m < 1) return 'เมื่อสักครู่';
  if (m < 60) return '$m นาทีที่แล้ว';
  final h = m ~/ 60;
  if (h < 24) return '$h ชั่วโมงที่แล้ว';
  final d = h ~/ 24;
  return '$d วันที่แล้ว';
}
