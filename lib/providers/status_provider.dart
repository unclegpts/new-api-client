import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class StatusState {
  final Map<String, dynamic>? status;
  final bool isLoading;
  final String? error;

  const StatusState({this.status, this.isLoading = false, this.error});
}

class StatusNotifier extends StateNotifier<StatusState> {
  final ApiClient _apiClient;

  StatusNotifier(this._apiClient) : super(const StatusState());

  Future<void> loadStatus() async {
    state = const StatusState(isLoading: true);
    try {
      final response = await _apiClient.dio.get('/api/status');
      if (response.data['success'] == true) {
        state = StatusState(status: response.data['data']);
      }
    } catch (e) {
      state = StatusState(error: e.toString());
    }
  }
}

final statusProvider = StateNotifierProvider<StatusNotifier, StatusState>((ref) {
  return StatusNotifier(ApiClient());
});
