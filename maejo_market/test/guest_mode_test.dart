import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/data/demo_data.dart';
import 'package:maejo_market/screens/auth/login_screen.dart';
import 'package:maejo_market/screens/buyer/buyer_shell.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/theme/app_colors.dart';
import 'package:maejo_market/theme/app_theme.dart';

/// โหมดผู้เยี่ยมชม — ผู้บริโภคที่ไม่อยากลงทะเบียนต้องเข้าดูตลาดได้ครบ
/// และสิ่งที่ต้องมีบัญชีต้องชวนเข้าสู่ระบบ ไม่ใช่เงียบหรือพัง
void main() {
  setUp(() {
    // ใส่ข้อมูลตรง ๆ แทน appState.init() เพราะโหมดจริงต่อ Firebase
    appState.shops = DemoData.shops();
    appState.stalls = DemoData.stalls();
    appState.banners = DemoData.banners();
    appState.ready = true;
    appState.user = null;
    appState.guest = true;
  });

  tearDown(() => appState.guest = false);

  Widget wrap(Widget child) {
    AppColors.applyMode(false);
    return MaterialApp(theme: AppTheme.theme(false), home: child);
  }

  Future<void> setPhone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('ผู้เยี่ยมชมเห็นร้านค้าและรู้ว่ากำลังดูแบบไม่ลงทะเบียน', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    expect(appState.isGuest, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.text('แนะนำสำหรับคุณ'), findsOneWidget);
    expect(find.text('สวนผักป้านวล'), findsWidgets);
    expect(find.text('กำลังเข้าชมแบบไม่ลงทะเบียน'), findsOneWidget);
  });

  testWidgets('กดติดตามร้านแล้วถูกชวนเข้าสู่ระบบ', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('เข้าสู่ระบบก่อนนะ'), findsOneWidget);
    // เลือก "ดูต่อก่อน" ต้องอยู่ในโหมดผู้เยี่ยมชมเหมือนเดิม
    await tester.tap(find.text('ดูต่อก่อน'));
    await tester.pump(const Duration(seconds: 1));
    expect(appState.guest, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('กดกระดิ่งแล้วชวนเข้าสู่ระบบ แทนกล่องแจ้งเตือนเปล่า', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('เข้าสู่ระบบก่อนนะ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('แท็บโปรไฟล์บอกว่าสมัครแล้วได้อะไรเพิ่ม และกดเข้าสู่ระบบได้', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ผู้เยี่ยมชม'), findsOneWidget);
    expect(find.text('ติดตามร้านโปรด'), findsOneWidget);
    expect(find.text('เปิดร้านของตัวเอง'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('เข้าสู่ระบบ').first);
    await tester.pump(const Duration(seconds: 1));
    // ออกจากโหมดผู้เยี่ยมชมแล้ว — ของจริง _Root จะสลับไปหน้าเข้าสู่ระบบให้เอง
    expect(appState.guest, isFalse);
  });

  testWidgets('ปุ่มในหน้าเข้าสู่ระบบพาเข้าโหมดผู้เยี่ยมชม', (tester) async {
    await setPhone(tester);
    appState.guest = false;
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump(const Duration(seconds: 1));

    final button = find.text('เข้าชมตลาดโดยไม่ต้องสมัคร');
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button);
    // โหลดข้อมูลสาธารณะล้มเหลวได้ (เทสต์ไม่มี Firebase) แต่ต้องยังเข้าโหมดผู้เยี่ยมชม
    await tester.pump(const Duration(seconds: 1));
    expect(appState.guest, isTrue);
  });

  testWidgets('แผนที่ตลาดดูได้โดยไม่ต้องล็อกอิน', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.map_outlined).first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('แผนที่ตลาด'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
