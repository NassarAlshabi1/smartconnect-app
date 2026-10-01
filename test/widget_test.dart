// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smartconnect/login_screen.dart';
import 'package:smartconnect/main.dart';

void main() {
  testWidgets('App boots and reaches the login screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The splash screen navigates to the login screen after 5 seconds.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Verify that the local login screen is shown.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
