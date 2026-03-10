import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chestsense/main.dart';
import 'package:chestsense/services/ml_service.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ChestSenseApp(mlService: MLService()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
