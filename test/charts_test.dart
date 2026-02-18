
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sam/screens/reports_screen.dart';

void main() {
  testWidgets('ReportsScreen renders with dummy data', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: ReportsScreen(),
    ));

    // Verify that the title is present (Header and Nav Item)
    expect(find.text('Reports'), findsAtLeastNWidgets(1));

    // Verify chart titles
    expect(find.text('Expense Breakdown'), findsOneWidget);
    expect(find.text('Income vs Expense'), findsOneWidget);

    // Verify filters
    expect(find.text('This Month'), findsOneWidget); // Dropdown default
    expect(find.text('Exclude Fixed'), findsOneWidget); // Switch label

    // Verify chart content (dummy data keys)
    // Donut chart legend/badges might be visible? 
    // The badge shows on touch, but let's check if the widget tree contains the chart classes
    // Note: fl_chart widgets paint on canvas, so finding text inside them might depend on implementation.
    // However, we can check if no error occurred.
  });
}
