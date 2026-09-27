import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/data/demo_data.dart';
import 'package:maejo_market/models/app_user.dart';
import 'package:maejo_market/models/shop.dart';
import 'package:maejo_market/screens/seller/payment_screen.dart';
import 'package:maejo_market/screens/seller/seller_shell.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/theme/app_colors.dart';
import 'package:maejo_market/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เมนูในแท็บ "จัดการร้าน" ของผู้ขายต้องพาไปที่ทำงานจริงทุกอัน
void main() {
  const myShop = Shop(
    id: 's-mine',
    name: 'ร้านทดสอบ',
    category: 'ผักสด',
    ownerName: 'ผู้ทดสอบ',
    stallId: 'A-1',
    zone: 'A',
    ownerUid: 'u-seller',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appState.shops = [myShop, ...DemoData.shops()];
    appState.stalls = DemoData.stalls();
    appState.banners = DemoData.banners();
    appState.ready = true;
    appState.guest = false;
    appState.myShops = [myShop];
    appState.myShop = myShop;
    appState.products = [];
    appState.sales = [];
    appState.user = const AppUser(
      uid: 'u-seller',
      name: 'แม่ค้าทดสอบ',
      email: 'seller@maejo.com',
      role: UserRole.seller,
      shopId: 's-mine',
    );
  });

  tearDown(() {
    appState.user = null;
    appState.myShop = null;
    appState.myShops = [];
  });

  Widget wrap(Widget child) {
    AppColors.applyMode(false);
    return MaterialApp(theme: AppTheme.theme(false), home: child);
  }

  /// เปิดแท็บ "จัดการร้าน"
  Future<void> openManageTab(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(SellerShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.storefront_outlined).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('จัดการสินค้า'), findsOneWidget);
  }

  testWidgets('เมนู "จัดการสินค้า" พาไปรายการสินค้าในแท็บหน้าหลัก', (tester) async {
    await openManageTab(tester);

    await tester.tap(find.text('จัดการสินค้า'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('จัดการสินค้า — อยู่ระหว่างพัฒนา'), findsNothing);
    expect(find.text('รายการสินค้าของฉัน'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('เมนู "ค่าเช่าแผงและแจ้งชำระ" เปิดหน้าค่าเช่าแผง', (tester) async {
    await openManageTab(tester);

    await tester.ensureVisible(find.text('ค่าเช่าแผงและแจ้งชำระ'));
    await tester.tap(find.text('ค่าเช่าแผงและแจ้งชำระ'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
