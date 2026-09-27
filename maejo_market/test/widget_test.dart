import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/app_config.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/models/app_user.dart';

/// เทสต์ชุดนี้ใช้ได้เฉพาะ Demo Mode (ข้อมูลจำลองในเครื่อง)
/// เมื่อ `AppConfig.useFirebase = true` การ init จะพยายามต่อ Firebase ซึ่ง unit test ทำไม่ได้
/// จึงข้ามไว้ ไม่ใช่ลบทิ้ง เผื่อกลับไปรันโหมดจำลองอีก
const _skipOnFirebase =
    AppConfig.useFirebase ? 'ใช้ได้เฉพาะ Demo Mode (ตอนนี้ AppConfig.useFirebase = true)' : null;

void main() {
  test('Demo Mode: ล็อกอินด้วยบัญชีแอดมินได้', skip: _skipOnFirebase, () async {
    await appState.init();
    final err = await appState.signIn('admin@maejo.com', '123456');
    expect(err, isNull);
    expect(appState.user?.role, UserRole.admin);
  });

  test('Demo Mode: อนุมัติคำขอแล้วจำนวนค้างลดลง', skip: _skipOnFirebase, () async {
    await appState.init();
    final before = appState.pendingCount;
    expect(before, greaterThan(0));
    final first = appState.pendingRequests.first;
    await appState.setRequestStatus(first.id, 'approved');
    expect(appState.pendingCount, before - 1);
  });
}
