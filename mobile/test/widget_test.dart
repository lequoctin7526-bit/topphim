import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineora/core/theme/app_theme.dart';
import 'package:cineora/shared/widgets/cineora_scaffold.dart';

void main() {
  testWidgets('CINEORA Theme and Shell Scaffold smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CineoraScaffold(
          child: Center(
            child: Text('CINEORA Test Body'),
          ),
        ),
      ),
    );

    // Verify UI mounts properly
    expect(find.text('CINEORA Test Body'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Yêu thích'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
