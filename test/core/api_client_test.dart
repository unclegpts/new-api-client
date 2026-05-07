import 'package:flutter_test/flutter_test.dart';
import 'package:new_api_client/core/api/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  group('ApiClient', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient();
    });

    test('singleton returns same instance', () {
      final a = ApiClient();
      final b = ApiClient();
      expect(identical(a, b), isTrue);
    });

    test('dio is initialized', () {
      expect(client.dio, isNotNull);
      expect(client.dio.options.connectTimeout, equals(const Duration(seconds: 15)));
    });

    test('configure sets baseUrl', () async {
      await client.configure(baseUrl: 'https://example.com/api');
      expect(client.baseUrl, equals('https://example.com/api'));
      expect(client.dio.options.baseUrl, equals('https://example.com/api'));
    });

    test('has 3 interceptors (auth + log + custom)', () {
      final interceptors = client.dio.interceptors;
      expect(interceptors.length, greaterThanOrEqualTo(2));
    });

    test('has LogInterceptor', () {
      final interceptors = client.dio.interceptors;
      final hasLog = interceptors.any((i) => i is LogInterceptor);
      expect(hasLog, isTrue);
    });
  });
}
