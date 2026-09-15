import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/app_config.dart';
import 'package:maejo_market/data/demo_data.dart';
import 'package:maejo_market/models/app_user.dart';
import 'package:maejo_market/screens/seller/seller_shell.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/theme/app_colors.dart';
import 'package:maejo_market/theme/app_theme.dart';

/// ผู้ขายต้องเชื่อม LINE ก่อนยื่นขอเปิดร้าน — ไม่งั้นแอดมินอาจอนุมัติไปก่อน
/// แล้วแจ้งเตือนผลอนุมัติไม่ถึงไลน์
void main() {
  const seller = AppUser(
    uid: 'u-seller-test',
    name: 'ผู้ขายทดสอบ',
    email: 'seller@test.com',
    phone: '0812345678',
    role: UserRole.seller,
    roles: [UserRole.seller],
  );

  setUp(() {
    appState.shops = DemoData.shops();
    appState.stalls = DemoData.stalls();
    appState.requests = [];
    appState.ready = true;
  });

  Widget host() {
    AppColors.applyMode(false);
    return MaterialApp(
      theme: AppTheme.theme(false),
      home: Scaffold(
        body: Builder(
          builder: (c) => Center(
            child: TextButton(
              onPressed: () => showApplyForShopDialog(c),
              child: const Text('เปิดฟอร์ม'),
            ),
          ),
        ),
      ),
    );
  }

  /// เปิดฟอร์มแล้วกรอกชื่อร้าน (ชื่อผู้ขอ/เบอร์เติมจากบัญชีให้แล้ว)
  Future<void> openAndFill(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.tap(find.text('เปิดฟอร์ม'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'ชื่อร้าน *'), 'ร้านทดสอบ');
    await tester.pump();
  }

  /// เลื่อนลงไปติ๊กยอมรับเงื่อนไข — ฟอร์มเป็น ListView แบบ lazy ช่องติ๊กจึงยังไม่ถูกสร้าง
  /// จนกว่าจะเลื่อนถึง (ตรวจข้อความด้านบนของฟอร์มให้เสร็จก่อนเรียก เพราะเลื่อนแล้วอาจหายไป)
  Future<void> acceptTerms(WidgetTester tester) async {
    final terms = find.byType(CheckboxListTile);
    final scrollable =
        find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(terms, 200, scrollable: scrollable);
    // เลื่อนต่อจนสุด ไม่งั้นช่องติ๊กอาจค้างอยู่ใต้แถบปุ่มด้านล่าง แตะแล้วไม่โดน
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(terms);
    await tester.pumpAndSettle();
    // ต้องติ๊กติดจริง ไม่งั้นเคส "ปุ่มกดไม่ได้" จะผ่านเพราะยังไม่ยอมรับเงื่อนไข ไม่ใช่เพราะ LINE
    expect(tester.widget<CheckboxListTile>(terms).value, isTrue);
  }

  bool sendEnabled(WidgetTester tester) {
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text('ส่งคำขอ'), matching: find.bySubtype<ButtonStyleButton>()),
    );
    return button.onPressed != null;
  }

  test('ตั้งค่า LINE ไว้แล้ว (ไม่งั้นเทสต์ชุดนี้ไม่มีความหมาย)', () {
    expect(AppConfig.lineReady, isTrue);
  });

  testWidgets('ผู้ขายยังไม่เชื่อม LINE กรอกครบแล้วก็ยังส่งคำขอไม่ได้', (tester) async {
    appState.user = seller;
    await openAndFill(tester);

    expect(find.text('ยังไม่ได้เชื่อม LINE'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'เชื่อมต่อ LINE'), findsOneWidget);

    await acceptTerms(tester);
    expect(sendEnabled(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ผู้ขายเชื่อม LINE แล้ว กรอกครบส่งคำขอได้', (tester) async {
    appState.user = seller.copyWith(lineUserId: 'Uline-test', lineDisplayName: 'ทดสอบ');
    await openAndFill(tester);

    expect(find.text('เชื่อม LINE แล้ว'), findsOneWidget);

    await acceptTerms(tester);
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('แอดมินที่เป็นผู้ขายด้วยไม่ต้องเชื่อม LINE', (tester) async {
    appState.user = seller.copyWith(roles: [UserRole.admin, UserRole.seller]);
    await openAndFill(tester);

    expect(find.text('เชื่อมต่อ LINE (ต้องทำก่อน)'), findsNothing);

    await acceptTerms(tester);
    expect(sendEnabled(tester), isTrue);
  });

  test('ยื่นคำขอตรง ๆ โดยไม่ผ่านฟอร์มก็ถูกปฏิเสธถ้ายังไม่เชื่อม LINE', () async {
    appState.user = seller;
    final err = await appState.applyForShop(shopName: 'ร้านทดสอบ', category: 'อาหาร');
    expect(err, 'เชื่อมต่อ LINE ก่อนยื่นขอเปิดร้าน');
    expect(appState.requests, isEmpty);
  });
}
