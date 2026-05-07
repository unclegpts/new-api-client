import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'layout/main_layout.dart';
import 'providers/auth_provider.dart';

// Pages
import 'pages/home/home_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/reset_password_page.dart';
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
      );
}

GoRouter createRouter({required AuthState authState}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isAdmin = authState.isAdmin;
      final loc = state.matchedLocation;
      final isPublic = loc == '/' || loc == '/about' || loc == '/pricing' || loc == '/setup' || loc == '/user-agreement' || loc == '/privacy-policy';
      final isAuth = loc == '/login' || loc == '/register' || loc == '/reset' || loc.startsWith('/oauth/') || loc.startsWith('/user/reset');
      final isAdminRoute = loc.startsWith('/console/channel') || loc.startsWith('/console/models') || loc.startsWith('/console/deployment') || loc.startsWith('/console/user_admin') || loc.startsWith('/console/redemption') || loc.startsWith('/console/subscription') || loc.startsWith('/console/setting');

      if (!isLoggedIn && !isPublic && !isAuth) return '/login';
      if (isLoggedIn && isAuth) return '/console';
      if (!isAdmin && isAdminRoute) return '/forbidden';
      return null;
    },
    routes: [
      // Public
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordPage()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
      GoRoute(path: '/pricing', builder: (_, __) => const PricingPage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/user-agreement', builder: (_, __) => const _PlaceholderPage('用户协议')),
      GoRoute(path: '/privacy-policy', builder: (_, __) => const _PlaceholderPage('隐私政策')),
      GoRoute(path: '/forbidden', builder: (_, __) => const _PlaceholderPage('403 禁止访问')),
      GoRoute(path: '/oauth/:provider', builder: (_, state) => _PlaceholderPage('OAuth: ${state.pathParameters['provider']}')),
      GoRoute(path: '/user/reset', builder: (_, __) => const _PlaceholderPage('重置密码确认')),

      // Console (wrapped in MainLayout)
      ShellRoute(
        builder: (_, __, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/console', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/console/chat', builder: (_, __) => const ChatPage()),
          GoRoute(path: '/console/chat/:id', builder: (_, state) => ChatPage(chatId: state.pathParameters['id'])),
          GoRoute(path: '/console/token', builder: (_, __) => const TokenListPage()),
          GoRoute(path: '/console/playground', builder: (_, __) => const PlaygroundPage()),
          GoRoute(path: '/console/topup', builder: (_, __) => const TopupPage()),
          GoRoute(path: '/console/log', builder: (_, __) => const LogPage()),
          GoRoute(path: '/console/midjourney', builder: (_, __) => const MidjourneyPage()),
          GoRoute(path: '/console/task', builder: (_, __) => const TaskPage()),
          GoRoute(path: '/console/personal', builder: (_, __) => const PersonalSettingPage()),
          // Admin
          GoRoute(path: '/console/channel', builder: (_, __) => const ChannelListPage()),
          GoRoute(path: '/console/models', builder: (_, __) => const ModelListPage()),
          GoRoute(path: '/console/deployment', builder: (_, __) => const DeploymentPage()),
          GoRoute(path: '/console/user_admin', builder: (_, __) => const UserListPage()),
          GoRoute(path: '/console/redemption', builder: (_, __) => const RedemptionPage()),
          GoRoute(path: '/console/subscription', builder: (_, __) => const SubscriptionPage()),
          GoRoute(path: '/console/setting', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
}
