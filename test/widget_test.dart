import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/main.dart';
import 'package:finmate/screens/splash_screen.dart';

void main() {
  testWidgets('finMate app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinMateApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
