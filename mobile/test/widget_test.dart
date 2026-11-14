import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineora/app/app.dart';

void main() {
  testWidgets('CINEORA App smoke test - starts and mounts MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CineoraApp(),
      ),
    );

    // Initial pump
    await tester.pump(const Duration(milliseconds: 100));

    // Verify MaterialApp mounts properly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
