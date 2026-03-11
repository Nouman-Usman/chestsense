import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chestsense/main.dart';
import 'package:chestsense/services/ml_service.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    // Note: This test requires Firebase to be initialized
    // For proper testing, use Firebase Test Lab or mock Firebase
    final mlService = MLService();
    await mlService.initialize();
    
    await tester.pumpWidget(ChestSenseApp(mlService: mlService));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
