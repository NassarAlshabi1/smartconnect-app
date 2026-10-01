import 'package:flutter_test/flutter_test.dart';
import 'package:smartconnect/local_auth_service.dart';

void main() {
  test('admin credentials authenticate locally', () async {
    final result = await AuthService.instance.signIn('admin', 'admin');
    expect(result.user.uid, 'admin-uid');
  });
}
