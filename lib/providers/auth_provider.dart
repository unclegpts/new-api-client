import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isAdmin;
  final String? username;
  final int role;
  final bool isLoading;

  const AuthState({
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.username,
    this.role = 0,
    this.isLoading = true,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAdmin,
    String? username,
    int? role,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
      username: username ?? this.username,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _checkSavedAuth();
  }

  Future<void> _checkSavedAuth() async {
    final token = await _apiClient.token;
    if (token != null) {
      state = state.copyWith(isLoggedIn: true, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post('/api/user/login', data: {
        'username': username,
        'password': password,
      });
      if (response.data['success'] == true) {
        final token = response.data['data'] as String;
        await _apiClient.setAuth(token: token, userId: username);
        state = AuthState(isLoggedIn: true, username: username);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.get('/api/user/logout');
    } catch (_) {}
    await _apiClient.clearAuth();
    state = const AuthState();
  }

  void setAdmin(bool isAdmin, {int role = 0}) {
    state = state.copyWith(isAdmin: isAdmin, role: role);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});
