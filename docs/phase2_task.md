# Claude Code Task: new-api-client Phase 2 — 项目骨架

## 项目路径
`/home/user/code/new-api-client`

## 目标
搭建 Flutter 项目全量基础设施，包括路由、网络、状态管理、存储、主题、国际化、布局框架和 28 个占位页面。所有页面只需占位 UI（标题+文字），为后续 Phase 3/4/5 实现留好路由和文件位置。

## 实现顺序
按依赖关系从上到下执行。每完成一个文件，确认无编译错误再继续。

---

## Task 1: 更新 pubspec.yaml

在项目根目录 `pubspec.yaml` 中，替换 dependencies 和 dev_dependencies 为以下内容（保留 flutter sdk 部分）：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.4
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  shared_preferences: ^2.3.4
  path_provider: ^2.1.5
  flutter_markdown: ^0.7.6
  fl_chart: ^0.70.2
  webview_flutter: ^4.10.0
  url_launcher: ^6.3.1
  package_info_plus: ^8.1.2
  intl: ^0.19.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  window_manager: ^0.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  drift_dev: ^2.22.0
  riverpod_generator: ^2.6.0
  flutter_lints: ^5.0.0
```

然后运行 `flutter pub get`。

---

## Task 2: 目录结构

创建以下目录（已存在的跳过）：
```
lib/
├── core/
│   ├── api/
│   ├── storage/
│   ├── theme/
│   └── i18n/
├── models/
├── providers/
├── layout/
├── widgets/
└── pages/
    ├── home/
    ├── auth/
    ├── setup/
    ├── dashboard/
    ├── chat/
    ├── playground/
    ├── token/
    ├── topup/
    ├── log_page/
    ├── midjourney/
    ├── task/
    ├── personal/
    ├── pricing/
    ├── admin/
    │   ├── channel/
    │   ├── model/
    │   ├── deployment/
    │   ├── user/
    │   ├── redemption/
    │   ├── subscription/
    │   └── settings/
    └── about/
```

---

## Task 3: 核心 — API 客户端 (`lib/core/api/api_client.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _baseUrl;

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Cache-Control': 'no-store'},
    ));
    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }

  Future<void> configure({required String baseUrl}) async {
    _baseUrl = baseUrl;
    dio.options.baseUrl = baseUrl;
  }

  String? get baseUrl => _baseUrl;

  Future<String?> get token => _secureStorage.read(key: 'auth_token');
  Future<String?> get userId => _secureStorage.read(key: 'user_id');

  Future<void> setAuth({required String token, required String userId}) async {
    await _secureStorage.write(key: 'auth_token', value: token);
    await _secureStorage.write(key: 'user_id', value: userId);
  }

  Future<void> clearAuth() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
  }

  Future<String?> getServerUrl() async {
    return _secureStorage.read(key: 'server_url');
  }

  Future<void> setServerUrl(String url) async {
    await _secureStorage.write(key: 'server_url', value: url);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient client;
  _AuthInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await client.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final userId = await client.userId;
    if (userId != null) {
      options.headers['New-API-User'] = userId;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      client.clearAuth();
    }
    handler.next(err);
  }
}
```

---

## Task 4: SSE 客户端 (`lib/core/api/sse_client.dart`)

```dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

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
```

---

## Task 5: 路由 (`lib/router.dart`)

完整的 GoRouter 配置，包含 28 个路由和守卫逻辑。所有页面先用占位 `PlaceholderPage` 替代。

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/home/home_page.dart';
import 'pages/setup/setup_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/playground/playground_page.dart';
import 'pages/token/token_list_page.dart';
import 'pages/topup/topup_page.dart';
import 'pages/log_page/log_page.dart';
import 'pages/midjourney/midjourney_page.dart';
import 'pages/task/task_page.dart';
import 'pages/personal/personal_setting_page.dart';
import 'pages/pricing/pricing_page.dart';
import 'pages/about/about_page.dart';
import 'pages/admin/channel/channel_list_page.dart';
import 'pages/admin/model/model_list_page.dart';
import 'pages/admin/deployment/deployment_page.dart';
import 'pages/admin/user/user_list_page.dart';
import 'pages/admin/redemption/redemption_page.dart';
import 'pages/admin/subscription/subscription_page.dart';
import 'pages/admin/settings/settings_page.dart';
import 'providers/auth_provider.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}

GoRouter createRouter({required AuthState authState}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isAdmin = authState.isAdmin;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/reset';
      final isAdminRoute = state.matchedLocation.startsWith('/console/channel') ||
          state.matchedLocation.startsWith('/console/models') ||
          state.matchedLocation.startsWith('/console/deployment') ||
          state.matchedLocation.startsWith('/console/user_admin') ||
          state.matchedLocation.startsWith('/console/redemption') ||
          state.matchedLocation.startsWith('/console/subscription') ||
          state.matchedLocation.startsWith('/console/setting');

      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/' &&
          state.matchedLocation != '/about' && state.matchedLocation != '/pricing' &&
          state.matchedLocation != '/setup') {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/console';
      }
      if (!isAdmin && isAdminRoute) {
        return '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordPage()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
      GoRoute(path: '/pricing', builder: (_, __) => const PricingPage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/user-agreement', builder: (_, __) => const PlaceholderPage(title: '用户协议')),
      GoRoute(path: '/privacy-policy', builder: (_, __) => const PlaceholderPage(title: '隐私政策')),
      GoRoute(path: '/forbidden', builder: (_, __) => const PlaceholderPage(title: '403 禁止访问')),
      GoRoute(path: '/oauth/:provider', builder: (_, state) => PlaceholderPage(title: 'OAuth: ${state.pathParameters['provider']}')),
      GoRoute(path: '/user/reset', builder: (_, __) => const PlaceholderPage(title: '重置密码确认')),
      
      // Console routes
      GoRoute(path: '/console', builder: (_, __) => const DashboardPage()),
      GoRoute(path: '/console/chat/:id', builder: (_, state) => ChatPage(chatId: state.pathParameters['id'])),
      GoRoute(path: '/console/chat', builder: (_, __) => const ChatPage()),
      GoRoute(path: '/console/token', builder: (_, __) => const TokenListPage()),
      GoRoute(path: '/console/playground', builder: (_, __) => const PlaygroundPage()),
      GoRoute(path: '/console/topup', builder: (_, __) => const TopupPage()),
      GoRoute(path: '/console/log', builder: (_, __) => const LogPage()),
      GoRoute(path: '/console/midjourney', builder: (_, __) => const MidjourneyPage()),
      GoRoute(path: '/console/task', builder: (_, __) => const TaskPage()),
      GoRoute(path: '/console/personal', builder: (_, __) => const PersonalSettingPage()),
      
      // Admin routes
      GoRoute(path: '/console/channel', builder: (_, __) => const ChannelListPage()),
      GoRoute(path: '/console/models', builder: (_, __) => const ModelListPage()),
      GoRoute(path: '/console/deployment', builder: (_, __) => const DeploymentPage()),
      GoRoute(path: '/console/user_admin', builder: (_, __) => const UserListPage()),
      GoRoute(path: '/console/redemption', builder: (_, __) => const RedemptionPage()),
      GoRoute(path: '/console/subscription', builder: (_, __) => const SubscriptionPage()),
      GoRoute(path: '/console/setting', builder: (_, __) => const SettingsPage()),
    ],
  );
}
```

---

## Task 6: 占位页面

创建 28 个占位页面文件，每个文件内容如下（替换 XXX 为页面名）：

```dart
import 'package:flutter/material.dart';

class XXX extends StatelessWidget {
  const XXX({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面名')),
      body: const Center(child: Text('页面名 - 待实现')),
    );
  }
}
```

页面列表（每个文件一个类）：
1. `pages/home/home_page.dart` → `HomePage`
2. `pages/auth/login_page.dart` → `LoginPage`
3. `pages/auth/register_page.dart` → `RegisterPage`
4. `pages/auth/reset_password_page.dart` → `ResetPasswordPage`
5. `pages/setup/setup_page.dart` → `SetupPage`
6. `pages/dashboard/dashboard_page.dart` → `DashboardPage`
7. `pages/chat/chat_page.dart` → `ChatPage`（带 `{String? chatId}` 参数）
8. `pages/playground/playground_page.dart` → `PlaygroundPage`
9. `pages/token/token_list_page.dart` → `TokenListPage`
10. `pages/topup/topup_page.dart` → `TopupPage`
11. `pages/log_page/log_page.dart` → `LogPage`
12. `pages/midjourney/midjourney_page.dart` → `MidjourneyPage`
13. `pages/task/task_page.dart` → `TaskPage`
14. `pages/personal/personal_setting_page.dart` → `PersonalSettingPage`
15. `pages/pricing/pricing_page.dart` → `PricingPage`
16. `pages/about/about_page.dart` → `AboutPage`
17. `pages/admin/channel/channel_list_page.dart` → `ChannelListPage`
18. `pages/admin/model/model_list_page.dart` → `ModelListPage`
19. `pages/admin/deployment/deployment_page.dart` → `DeploymentPage`
20. `pages/admin/user/user_list_page.dart` → `UserListPage`
21. `pages/admin/redemption/redemption_page.dart` → `RedemptionPage`
22. `pages/admin/subscription/subscription_page.dart` → `SubscriptionPage`
23. `pages/admin/settings/settings_page.dart` → `SettingsPage`

---

## Task 7: Auth Provider (`lib/providers/auth_provider.dart`)

```dart
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
```

---

## Task 8: Status Provider (`lib/providers/status_provider.dart`)

```dart
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
```

---

## Task 9: 主题系统 (`lib/core/theme/app_theme.dart`)

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF6750A4),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF6750A4),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

---

## Task 10: 主题 Provider (`lib/providers/theme_provider.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

enum AppThemeMode { light, dark, system }

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = ThemeMode.values.firstWhere((e) => e.name == value, orElse: () => ThemeMode.system);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
```

---

## Task 11: 布局框架

### 11a: `lib/layout/main_layout.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'header_bar.dart';
import 'side_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _sidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: const Text('New API'),
        ),
        drawer: Drawer(child: SideBar(collapsed: false, onToggle: () {})),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SideBar(
            collapsed: _sidebarCollapsed,
            onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const HeaderBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 11b: `lib/layout/header_bar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class HeaderBar extends ConsumerWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text('New API', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            tooltip: isDark ? '浅色模式' : '深色模式',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
```

### 11c: `lib/layout/side_bar.dart`

```dart
import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const SideBar({super.key, required this.collapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 64 : 260,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavGroup(context, '聊天', Icons.chat, [
                  _NavItem(icon: Icons.terminal, label: '操练场', route: '/console/playground'),
                  _NavItem(icon: Icons.message, label: '聊天', route: '/console/chat'),
                ]),
                const Divider(),
                _buildNavGroup(context, '控制台', Icons.dashboard, [
                  _NavItem(icon: Icons.analytics, label: '数据看板', route: '/console'),
                  _NavItem(icon: Icons.vpn_key, label: '令牌管理', route: '/console/token'),
                  _NavItem(icon: Icons.history, label: '使用日志', route: '/console/log'),
                  _NavItem(icon: Icons.image, label: '绘图日志', route: '/console/midjourney'),
                  _NavItem(icon: Icons.task, label: '任务日志', route: '/console/task'),
                ]),
                const Divider(),
                _buildNavGroup(context, '个人中心', Icons.person, [
                  _NavItem(icon: Icons.wallet, label: '钱包管理', route: '/console/topup'),
                  _NavItem(icon: Icons.settings, label: '个人设置', route: '/console/personal'),
                ]),
                const Divider(),
                _buildNavGroup(context, '管理员', Icons.admin_panel_settings, [
                  _NavItem(icon: Icons.cable, label: '渠道管理', route: '/console/channel'),
                  _NavItem(icon: Icons.subscriptions, label: '订阅管理', route: '/console/subscription'),
                  _NavItem(icon: Icons.model_training, label: '模型管理', route: '/console/models'),
                  _NavItem(icon: Icons.rocket_launch, label: '模型部署', route: '/console/deployment'),
                  _NavItem(icon: Icons.card_giftcard, label: '兑换码', route: '/console/redemption'),
                  _NavItem(icon: Icons.people, label: '用户管理', route: '/console/user_admin'),
                  _NavItem(icon: Icons.tune, label: '系统设置', route: '/console/setting'),
                ]),
              ],
            ),
          ),
          InkWell(
            onTap: onToggle,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup(BuildContext context, String title, IconData icon, List<_NavItem> items) {
    if (collapsed) {
      return Column(
        children: items.map((item) => _buildCollapsedItem(context, item)).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
        ),
        ...items.map((item) => _buildExpandedItem(context, item)),
      ],
    );
  }

  Widget _buildExpandedItem(BuildContext context, _NavItem item) {
    return ListTile(
      dense: true,
      leading: Icon(item.icon, size: 20),
      title: Text(item.label, style: const TextStyle(fontSize: 14)),
      onTap: () => Navigator.of(context).pushNamed(item.route),
    );
  }

  Widget _buildCollapsedItem(BuildContext context, _NavItem item) {
    return Tooltip(
      message: item.label,
      child: IconButton(
        icon: Icon(item.icon),
        onPressed: () => Navigator.of(context).pushNamed(item.route),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
```

---

## Task 12: `lib/main.dart` — 入口

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'layout/main_layout.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final router = createRouter(authState: authState);

    return MaterialApp.router(
      title: 'New API',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

---

## Task 13: 通用 UI 组件

### 13a: `lib/widgets/card_pro.dart`

```dart
import 'package:flutter/material.dart';

class CardPro extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const CardPro({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || actions != null)
              Row(
                children: [
                  if (title != null)
                    Text(title!, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            if (title != null || actions != null) const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
```

### 13b: `lib/widgets/stats_card.dart`

```dart
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Task 14: 验证

完成所有文件后：
1. 运行 `flutter pub get`
2. 运行 `flutter analyze` — 必须 0 错误
3. 运行 `flutter build linux --debug` — 确认编译通过
