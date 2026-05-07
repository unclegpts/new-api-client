import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('SSE parsing', () {
    test('parses basic SSE data line', () {
      const line = 'data: {"choices":[{"delta":{"content":"Hello"}}]}';
      final data = line.substring(6);
      final json = jsonDecode(data);
      final content = json['choices'][0]['delta']['content'];
      expect(content, equals('Hello'));
    });

    test('handles [DONE] marker', () {
      const line = 'data: [DONE]';
      final data = line.substring(6);
      expect(data, equals('[DONE]'));
    });

    test('parses multi-choice response', () {
      const line = 'data: {"choices":[{"delta":{"content":"A"}},{"delta":{"content":"B"}}]}';
      final data = line.substring(6);
      final json = jsonDecode(data);
      expect(json['choices'].length, equals(2));
    });

    test('handles null delta gracefully', () {
      const line = 'data: {"choices":[{"delta":null}]}';
      final data = line.substring(6);
      final json = jsonDecode(data);
      final delta = json['choices'][0]['delta'];
      expect(delta, isNull);
    });
  });
}
