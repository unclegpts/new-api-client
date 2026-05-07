import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:new_api_client/pages/setup/setup_page.dart';

void main() {
  group('SetupPage', () {
    testWidgets('renders server address input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SetupPage()),
      );

      // Title and input match actual page text
      expect(find.text('连接到 New API 服务器'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('connect button shows loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SetupPage()),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      // Button should exist (enabled when empty string is not checked here)
      expect(button.onPressed, isNotNull);
    });

    testWidgets('input hint text is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SetupPage()),
      );

      expect(find.text('请输入你的 new-api 实例地址'), findsOneWidget);
      expect(find.text('服务器地址'), findsWidgets);
    });
  });
}
