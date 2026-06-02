import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nlf/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build the app widget tree
    await tester.pumpWidget(const MyApp());

    // Verify the app loads a MaterialApp widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
