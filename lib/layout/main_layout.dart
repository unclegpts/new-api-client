import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
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
  int _bottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  LayoutMode get _layoutMode {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return LayoutMode.mobile;
    if (w < 900) return LayoutMode.tablet;
    return LayoutMode.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final l10n = context.l10n;

    switch (_layoutMode) {
      case LayoutMode.mobile:
        return _buildMobile(context, isDark, l10n);
      case LayoutMode.tablet:
        return _buildTablet(context, isDark);
      case LayoutMode.desktop:
        return _buildDesktop(context, isDark);
    }
  }

  // ── Mobile: Bottom Nav + Drawer ──
  Widget _buildMobile(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('New API'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: SideBar(
            collapsed: false,
            onToggle: () => Navigator.pop(context),
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) {
          setState(() => _bottomNavIndex = i);
          // Navigate based on index
          final routes = [
            '/console/chat',
            '/console',
            '/console/topup',
            '/console/channel',
          ];
          if (i < routes.length) {
            Navigator.of(context).pushNamed(routes[i]);
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.message), label: l10n.t('nav_chat')),
          NavigationDestination(icon: const Icon(Icons.analytics), label: l10n.t('dashboard_title')),
          NavigationDestination(icon: const Icon(Icons.person), label: l10n.t('nav_personal')),
          NavigationDestination(icon: const Icon(Icons.admin_panel_settings), label: l10n.t('nav_channel')),
        ],
      ),
    );
  }

  // ── Tablet: Narrow sidebar always visible ──
  Widget _buildTablet(BuildContext context, bool isDark) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          SideBar(
            collapsed: true,
            onToggle: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                HeaderBar(
                  isDark: isDark,
                  onThemeToggle: () => ref.read(themeProvider.notifier).toggle(),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: SideBar(
            collapsed: false,
            onToggle: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  // ── Desktop: Full sidebar ──
  Widget _buildDesktop(BuildContext context, bool isDark) {
    // Keyboard shortcuts
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            () => ref.read(themeProvider.notifier).toggle(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              SideBar(
                collapsed: _sidebarCollapsed,
                onToggle: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    HeaderBar(
                      isDark: isDark,
                      onThemeToggle: () =>
                          ref.read(themeProvider.notifier).toggle(),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LayoutMode { mobile, tablet, desktop }
