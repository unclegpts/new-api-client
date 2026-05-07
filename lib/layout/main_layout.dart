import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import '../core/api/api_client.dart';
import 'header_bar.dart';
import 'side_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final _client = ApiClient();
  bool _sidebarCollapsed = false;
  int _bottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _noticeChecked = false;

  LayoutMode get _layoutMode {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return LayoutMode.mobile;
    if (w < 900) return LayoutMode.tablet;
    return LayoutMode.desktop;
  }

  @override
  void initState() {
    super.initState();
    _checkNotice();
  }

  Future<void> _checkNotice() async {
    if (_noticeChecked) return;
    _noticeChecked = true;
    try {
      final res = await _client.dio.get('/api/notice');
      if (res.data['success'] == true && mounted) {
        final notice = res.data['data'];
        if (notice is Map && notice['content']?.toString().isNotEmpty == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showNoticeDialog(notice);
          });
        }
      }
    } catch (_) {}
  }

  void _showNoticeDialog(Map notice) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(notice['title']?.toString() ?? '公告'),
      content: SingleChildScrollView(child: Text(notice['content']?.toString() ?? '')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    ));
  }

  void _showGlobalSearch() {
    showSearch(context: context, delegate: _GlobalSearchDelegate(_client));
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

  Widget _buildMobile(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('New API'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showGlobalSearch),
          IconButton(icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode), onPressed: () => ref.read(themeProvider.notifier).toggle()),
          IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),
      drawer: Drawer(child: SafeArea(child: SideBar(collapsed: false, onToggle: () => Navigator.pop(context)))),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) {
          setState(() => _bottomNavIndex = i);
          final routes = ['/console/chat', '/console', '/console/topup', '/console/channel'];
          if (i < routes.length) Navigator.of(context).pushNamed(routes[i]);
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

  Widget _buildTablet(BuildContext context, bool isDark) {
    return Scaffold(
      body: Row(children: [
        SideBar(collapsed: true, onToggle: () => _scaffoldKey.currentState?.openDrawer()),
        const VerticalDivider(width: 1),
        Expanded(child: Column(children: [
          HeaderBar(isDark: isDark, onThemeToggle: () => ref.read(themeProvider.notifier).toggle(), onSearch: _showGlobalSearch),
          Expanded(child: widget.child),
        ])),
      ]),
      drawer: Drawer(child: SafeArea(child: SideBar(collapsed: false, onToggle: () => Navigator.pop(context)))),
    );
  }

  Widget _buildDesktop(BuildContext context, bool isDark) {
    return CallbackShortcuts(bindings: {
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      const SingleActivator(LogicalKeyboardKey.keyD, control: true): () => ref.read(themeProvider.notifier).toggle(),
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): _showGlobalSearch,
    }, child: Focus(autofocus: true, child: Scaffold(
      body: Row(children: [
        SideBar(collapsed: _sidebarCollapsed, onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed)),
        const VerticalDivider(width: 1),
        Expanded(child: Column(children: [
          HeaderBar(isDark: isDark, onThemeToggle: () => ref.read(themeProvider.notifier).toggle(), onSearch: _showGlobalSearch),
          Expanded(child: widget.child),
        ])),
      ]),
    )));
  }
}

// ── 全局搜索 ──
class _GlobalSearchDelegate extends SearchDelegate<String> {
  final ApiClient client;
  _GlobalSearchDelegate(this.client);

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    if (query.length < 2) return const Center(child: Text('输入至少2个字符搜索'));
    return FutureBuilder(
      future: _search(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data as List<_SearchItem>;
        if (items.isEmpty) return const Center(child: Text('未找到结果'));
        return ListView(children: items.map((item) => ListTile(
          leading: Icon(item.icon, size: 20),
          title: Text(item.title),
          subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
          onTap: () { Navigator.pushNamed(context, item.route); close(context, ''); },
        )).toList());
      },
    );
  }

  Future<List<_SearchItem>> _search() async {
    final items = <_SearchItem>[];
    try {
      final res = await client.dio.get('/api/user/', queryParameters: {'keyword': query, 'p': 0, 'size': 5});
      if (res.data['success'] == true) {
        for (final u in (res.data['data'] ?? [])) {
          items.add(_SearchItem(Icons.person, u['username'] ?? '用户', '用户', '/console/user_admin'));
        }
      }
    } catch (_) {}
    items.add(_SearchItem(Icons.vpn_key, 'Token: $query', '令牌', '/console/token'));
    items.add(_SearchItem(Icons.history, 'Log: $query', '使用日志', '/console/log'));
    return items;
  }
}

class _SearchItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  _SearchItem(this.icon, this.title, this.subtitle, this.route);
}

enum LayoutMode { mobile, tablet, desktop }
