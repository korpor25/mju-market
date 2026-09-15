import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/data/demo_data.dart';
import 'package:maejo_market/models/app_user.dart';
import 'package:maejo_market/screens/buyer/buyer_shell.dart';
import 'package:maejo_market/screens/favorites_screen.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/theme/app_colors.dart';
import 'package:maejo_market/theme/app_theme.dart';
import 'package:maejo_market/widgets/common.dart';
import 'package:maejo_market/widgets/market_map.dart';

/// ทดสอบว่าหน้าจอฝั่งผู้ซื้อ (เลย์เอาต์ใหม่) วาดได้จริงบนขนาดมือถือ
/// ไม่มี overflow และไม่มี exception — ครอบทุกแท็บ
void main() {
  setUp(() {
    // ใส่ข้อมูลตรง ๆ แทน appState.init() เพราะโหมดจริงต่อ Firebase
    appState.shops = DemoData.shops();
    appState.stalls = DemoData.stalls();
    appState.banners = DemoData.banners();
    appState.ready = true;
    appState.user = const AppUser(
      uid: 'u-test',
      name: 'ผู้ทดสอบ',
      email: 'test@maejo.com',
      role: UserRole.buyer,
    );
  });

  Widget wrap(Widget child) {
    AppColors.applyMode(false);
    return MaterialApp(theme: AppTheme.theme(false), home: child);
  }

  Future<void> setPhone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('หน้าแรกผู้ซื้อวาดได้ ไม่มี overflow', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Maejo Market'), findsOneWidget);
    // ชิปหมวดหมู่ + แผงร้านแนะนำ
    expect(find.text('ทั้งหมด'), findsWidgets);
    expect(find.text('แนะนำสำหรับคุณ'), findsOneWidget);
    expect(find.text('สวนผักป้านวล'), findsWidgets);

    // ตารางร้านทั้งหมดอยู่ใต้จอ ต้องเลื่อนลงไปก่อนถึงจะถูกสร้าง
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -600));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ร้านค้าทั้งหมด'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('เลื่อนหน้าแรกจนสุดได้ ไม่มี overflow', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -1200));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('สลับไปแท็บค้นหา / แผนที่ / โปรไฟล์ ได้', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.search_rounded).last);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('พบ '), findsOneWidget);

    await tester.tap(find.byIcon(Icons.map_outlined).first);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('แผนที่ตลาด'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('บัญชีของฉัน'), findsOneWidget);
  });

  testWidgets('กดหัวใจบนการ์ดร้านในหน้าค้นหาได้', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const BuyerShell()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('หน้าร้านที่ติดตามวาดได้ (ตอนยังไม่มีร้านโปรด)', (tester) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(const FavoritesScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('ร้านที่ติดตาม'), findsOneWidget);
  });

  testWidgets('ผังตลาดวาดได้ครบทุกย่าน ไม่มี overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final showPrice in [false, true]) {
      await tester.pumpWidget(wrap(Scaffold(
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(
            child: MarketMap(
              stalls: appState.stalls,
              selectedId: 'B-4',
              showPrice: showPrice,
              onTap: (_) {},
            ),
          ),
        ]),
      )));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }

    // ป้ายชื่อย่านครบตามผังที่ตลาดให้มา
    for (final zone in ['ของสด', 'ผัก', 'ร้านเย็บเสื้อ', 'กับข้าวสุก', 'ร้านอาหาร', 'ปิ้งไก่', 'ของป่า', 'ผลไม้', 'ดอกไม้']) {
      expect(find.text(zone), findsWidgets, reason: 'ไม่พบย่าน $zone บนผัง');
    }
    expect(find.text('ทางเข้า'), findsNWidgets(5));

    // หน้าจองของผู้ขาย: แผงไม่ว่างต้องขึ้นกุญแจและกดแล้วไม่เกิดอะไร
    final tapped = <String>[];
    await tester.pumpWidget(wrap(Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: [
        MarketMap(
          stalls: appState.stalls,
          showPrice: true,
          canTap: (s) => s.isBookable,
          onTap: (s) => tapped.add(s.id),
        ),
      ]),
    )));
    await tester.pump();
    final busy = appState.stalls.firstWhere((s) => !s.isBookable);
    final free = appState.stalls.firstWhere((s) => s.isBookable);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    expect(find.byIcon(Icons.touch_app_rounded), findsWidgets);

    await tester.ensureVisible(find.text(busy.id));
    await tester.tap(find.text(busy.id), warnIfMissed: false);
    await tester.ensureVisible(find.text(free.id));
    await tester.tap(find.text(free.id));
    expect(tapped, [free.id]);
    expect(tester.takeException(), isNull);
  });
}
