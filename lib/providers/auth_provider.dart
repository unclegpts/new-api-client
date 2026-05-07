import 'package:flutter/foundation.dart';
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
      // 有 token = 之前登录过（session cookie 不一定持久化，但用 token 标记状态）
      state = state.copyWith(isLoggedIn: true, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 登录：使用 session cookie 认证
  /// 返回 true=成功, false=失败, null=需要2FA
  Future<bool?> login(String username, String password) async {
    try {
      // Step 1: 账号密码登录，获取 session cookie
      final loginResp = await _apiClient.dio.post('/api/user/login', data: {
        'username': username,
        'password': password,
      });

      if (loginResp.data['success'] != true) {
        return false;
      }

      final data = loginResp.data['data'];
      if (data == null) {
        return false;
      }

      // 检查是否需要 2FA
      if (data is Map && data['require_2fa'] == true) {
        return null; // 需要 2FA
      }

      // Step 2: 用 session cookie 获取 access token（供 API 场景用）
      try {
        final tokenResp = await _apiClient.dio.get('/api/user/self/token');
        if (tokenResp.data['success'] == true) {
          final token = tokenResp.data['data'] as String;
          await _apiClient.setAuth(token: token, userId: username);
        }
      } catch (_) {
        // token 获取失败不影响登录，session cookie 已可用
      }

      final isAdmin = (data['role'] ?? 0) >= 10;
      state = AuthState(
        isLoggedIn: true,
        isAdmin: isAdmin,
        username: data['username']?.toString(),
        role: data['role'] ?? 0,
      );
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.get('/api/user/logout');
    } catch (_) {}
    await _apiClient.clearAuth();
    await _apiClient.clearCookies();
    state = const AuthState();
  }

  void setAdmin(bool isAdmin, {int role = 0}) {
    state = state.copyWith(isAdmin: isAdmin, role: role);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});
