import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../widgets/common.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _client = ApiClient();
  bool _loading = true;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _client.dio.get('/api/status'),
        _client.dio.get('/api/user/self'),
      ]);
      if (mounted) {
        setState(() {
          _status = results[0].data['success'] == true ? results[0].data['data'] : null;
          _stats = results[1].data['success'] == true ? results[1].data['data'] : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final systemName = _status?['system_name'] ?? 'New API';
    final nickname = _stats?['nickname'] ?? _stats?['display_name'] ?? '用户';
    final quota = _stats?['quota'] ?? 0;
    final usedQuota = _stats?['used_quota'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('欢迎回来, $nickname', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(systemName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),

          // Stats cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatsCard(
                title: '总额度',
                value: '\$${_formatUsd(quota)}',
                icon: Icons.account_balance_wallet,
                color: theme.colorScheme.primary,
              ),
              StatsCard(
                title: '已使用',
                value: '\$${_formatUsd(usedQuota)}',
                icon: Icons.trending_up,
                color: theme.colorScheme.tertiary,
              ),
              StatsCard(
                title: '剩余额度',
                value: '\$${_formatUsd(quota - usedQuota)}',
                icon: Icons.savings,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick actions
          CardPro(
            title: '快捷入口',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAction(Icons.message, '聊天', '/console/chat', theme),
                _QuickAction(Icons.terminal, '操练场', '/console/playground', theme),
                _QuickAction(Icons.vpn_key, '令牌管理', '/console/token', theme),
                _QuickAction(Icons.wallet, '充值', '/console/topup', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUsd(dynamic v) {
    if (v == null) return '0.00';
    final n = v is double ? v : (v is int ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return n.toStringAsFixed(2);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final ThemeData theme;
  const _QuickAction(this.icon, this.label, this.route, this.theme);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
