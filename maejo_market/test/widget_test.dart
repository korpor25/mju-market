import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/state/app_state.dart';
import 'package:maejo_market/models/app_user.dart';

void main() {
  test('Demo Mode: ล็อกอินด้วยบัญชีแอดมินได้', () async {
    await appState.init();
    final err = await appState.signIn('admin@maejo.com', '123456');
    expect(err, isNull);
    expect(appState.user?.role, UserRole.admin);
  });

  test('Demo Mode: อนุมัติคำขอแล้วจำนวนค้างลดลง', () async {
    await appState.init();
    final before = appState.pendingCount;
    expect(before, greaterThan(0));
    final first = appState.pendingRequests.first;
    await appState.setRequestStatus(first.id, 'approved');
    expect(appState.pendingCount, before - 1);
  });
}
