import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'router.dart';
import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 恢复已保存的服务器地址
  final apiClient = ApiClient();
  final savedUrl = await apiClient.getServerUrl();
  if (savedUrl != null && savedUrl.isNotEmpty) {
    await apiClient.configure(baseUrl: savedUrl);
  }

  // 桌面窗口管理
  await windowManager.ensureInitialized();
  final windowOptions = WindowOptions(
    size: const Size(1280, 800),
    minimumSize: const Size(800, 600),
    title: 'New API Client',
    center: true,
    backgroundColor: Colors.transparent,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  static const _locale = Locale('zh', 'CN');
  late final ValueNotifier<AuthState> _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // 监听认证状态变化 → GoRouter 自动重评估 redirect
    _authNotifier = ValueNotifier(const AuthState());
    _router = createRouter(refreshListenable: _authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // 同步认证状态到 GoRouter 的 refreshListenable
    if (_authNotifier.value != authState) {
      _authNotifier.value = authState;
    }

    return MaterialApp.router(
      title: 'New API Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: _locale,
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
