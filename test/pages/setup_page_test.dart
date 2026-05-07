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
      expect(find.text('测试连接并保存'), findsOneWidget);
    });

    testWidgets('connect button is enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SetupPage()),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows server tips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SetupPage()),
      );

      expect(find.text('统一管理和分发多种 LLM'), findsOneWidget);
      expect(find.text('试试这些地址：'), findsOneWidget);
    });
  });
}
