import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/data/demo_data.dart';
import 'package:maejo_market/models/app_user.dart';
import 'package:maejo_market/models/shop.dart';
import 'package:maejo_market/screens/help_screen.dart';
import 'package:maejo_market/screens/history_screen.dart';
import 'package:maejo_market/screens/profile_tab.dart';
import 'package:maejo_market/screens/settings_screen.dart';
import 'package:maejo_market/services/visit_history.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/theme/app_colors.dart';
import 'package:maejo_market/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เมนูในหน้าบัญชีต้องมีปลายทางจริงทุกอัน — ห้ามเหลือ "อยู่ระหว่างพัฒนา"
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appState.shops = DemoData.shops();
    appState.stalls = DemoData.stalls();
    appState.banners = DemoData.banners();
    appState.ready = true;
    appState.guest = false;
    appState.user = const AppUser(
      uid: 'u-test',
      name: 'ผู้ทดสอบ',
      email: 'test@maejo.com',
      role: UserRole.buyer,
    );
  });

  tearDown(() => appState.user = null);

  Widget wrap(Widget child) {
    AppColors.applyMode(false);
    return MaterialApp(theme: AppTheme.theme(false), home: Scaffold(body: child));
  }

  Future<void> setPhone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('ไม่มีเมนูไหนในหน้าบัญชีขึ้น "อยู่ระหว่างพัฒนา" อีก', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const ProfileTab()));
    await tester.pump(const Duration(seconds: 1));

    const opens = {
      'ประวัติการเข้าชม': HistoryScreen,
      'ตั้งค่า': SettingsScreen,
      'ช่วยเหลือ / ติดต่อเรา': HelpScreen,
    };

    for (final entry in opens.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      // pump แรกเริ่ม transition, pump ที่สองรอจนหน้าใหม่วาดเสร็จ
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('${entry.key} — อยู่ระหว่างพัฒนา'), findsNothing,
          reason: '${entry.key} ยังเป็นเมนูหลอก');
      expect(find.byType(entry.value), findsOneWidget,
          reason: '${entry.key} ต้องเปิดหน้า ${entry.value}');
      expect(tester.takeException(), isNull);

      // กลับมาหน้าบัญชีเพื่อกดเมนูถัดไป
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('เมนูประวัติ/ตั้งค่า/ช่วยเหลือ เปิดหน้าที่ถูกต้อง', (tester) async {
    await setPhone(tester);

    await tester.pumpWidget(wrap(const HistoryScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ประวัติการเข้าชม'), findsOneWidget);
    expect(find.textContaining('ยังไม่มีประวัติการเข้าชม'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('โหมดกลางคืน'), findsOneWidget);
    expect(find.text('ล้างประวัติการเข้าชม'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(wrap(const HelpScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('คำถามที่พบบ่อย'), findsOneWidget);
    expect(find.text('ไม่อยากสมัครสมาชิก ใช้งานได้ไหม'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ผู้เยี่ยมชมก็เข้าประวัติ/ตั้งค่า/ช่วยเหลือ ได้', (tester) async {
    await setPhone(tester);
    appState.user = null;
    appState.guest = true;
    addTearDown(() => appState.guest = false);

    await tester.pumpWidget(wrap(const ProfileTab()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ผู้เยี่ยมชม'), findsOneWidget);
    for (final label in ['ประวัติการเข้าชม', 'ตั้งค่า', 'ช่วยเหลือ / ติดต่อเรา']) {
      expect(find.text(label), findsOneWidget, reason: 'ผู้เยี่ยมชมควรเห็นเมนู $label');
    }

    await tester.ensureVisible(find.text('ตั้งค่า'));
    await tester.tap(find.text('ตั้งค่า'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // ผู้เยี่ยมชมไม่มีบัญชี จึงไม่ควรเห็นเมนูที่ผูกกับบัญชี
    expect(find.text('โหมดกลางคืน'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('ประวัติการเข้าชม: บันทึก / เรียงใหม่ก่อน / ไม่ซ้ำ / ล้างได้', () async {
    SharedPreferences.setMockInitialValues({});
    const a = Shop(
        id: 's-a', name: 'ร้าน ก', category: 'ผักสด', ownerName: '', stallId: 'A-1', zone: 'A');
    const b = Shop(
        id: 's-b', name: 'ร้าน ข', category: 'อาหาร', ownerName: '', stallId: 'B-2', zone: 'B');

    expect(await VisitHistory.load(), isEmpty);

    await VisitHistory.record(a);
    await VisitHistory.record(b);
    var list = await VisitHistory.load();
    expect(list.map((v) => v.id).toList(), ['s-b', 's-a'], reason: 'ร้านล่าสุดต้องอยู่บนสุด');
    expect(list.first.whereLabel, 'โซน B · แผง B-2 · อาหาร');

    // เข้าดูร้านเดิมซ้ำ = เลื่อนขึ้นบนสุด ไม่เพิ่มรายการใหม่
    await VisitHistory.record(a);
    list = await VisitHistory.load();
    expect(list.map((v) => v.id).toList(), ['s-a', 's-b']);

    await VisitHistory.clear();
    expect(await VisitHistory.load(), isEmpty);
  });

  test('ประวัติเก็บไม่เกินที่กำหนด', () async {
    SharedPreferences.setMockInitialValues({});
    for (var i = 0; i < VisitHistory.maxItems + 5; i++) {
      await VisitHistory.record(
          Shop(id: 's-$i', name: 'ร้าน $i', category: '', ownerName: '', stallId: '', zone: ''));
    }
    final list = await VisitHistory.load();
    expect(list.length, VisitHistory.maxItems);
    expect(list.first.id, 's-${VisitHistory.maxItems + 4}');
  });
}
