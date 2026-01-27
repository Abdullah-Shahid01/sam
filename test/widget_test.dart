import 'package:flutter_test/flutter_test.dart';
import 'package:sam/main.dart';

void main() {
  testWidgets('Dashboard screen shows title', (WidgetTester tester) async{
    await tester.pumpWidget(const SAMApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
