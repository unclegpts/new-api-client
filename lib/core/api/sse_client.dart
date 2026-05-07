import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class SseEvent {
  final String? id;
  final String? event;
  final String data;
  SseEvent({this.id, this.event, required this.data});
}

class SseClient {
  final ApiClient apiClient;
  CancelToken? _cancelToken;

  SseClient(this.apiClient);

  Stream<SseEvent> connect(String path, {Map<String, dynamic>? body}) {
    _cancelToken = CancelToken();
    final controller = StreamController<SseEvent>();

    apiClient.dio.post(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
      cancelToken: _cancelToken,
    ).then((response) {
      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      stream.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                controller.close();
                return;
              }
              controller.add(SseEvent(data: data));
            }
          }
        },
        onError: (error) => controller.addError(error),
        onDone: () => controller.close(),
        cancelOnError: false,
      );
    }).catchError((error) {
      controller.addError(error);
    });

    return controller.stream;
  }

  void cancel() {
    _cancelToken?.cancel();
  }
}
