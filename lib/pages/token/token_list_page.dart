import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class TokenListPage extends StatefulWidget {
  const TokenListPage({super.key});

  @override
  State<TokenListPage> createState() => _TokenListPageState();
}

class _TokenListPageState extends State<TokenListPage> {
  final _client = ApiClient();
  List<dynamic> _tokens = [];
  bool _loading = true;
  String? _error;
  final int _page = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.get('/api/token/', queryParameters: {
        'p': _page,
        'size': _pageSize,
      });
      if (res.data['success'] == true && mounted) {
        setState(() {
          _tokens = (res.data['data'] as List?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  Color _statusColor(dynamic status) {
    return status == 1 ? Colors.green : Colors.red;
  }

  String _statusText(dynamic status) {
    return status == 1 ? '启用' : '禁用';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('令牌管理'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTokens),
      ]),
      body: _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: _loadTokens, child: const Text('重试')),
            ]))
          : _tokens.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_off, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  const Text('暂无令牌'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _tokens.length,
              itemBuilder: (context, idx) {
                final t = _tokens[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(t['status']).withValues(alpha: 0.1),
                      child: Icon(Icons.vpn_key, color: _statusColor(t['status']), size: 20),
                    ),
                    title: Text(t['name'] ?? '未命名', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(_maskKey(t['key'] ?? ''), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_statusText(t['status']), style: TextStyle(color: _statusColor(t['status']), fontSize: 12)),
                        Text('\$${((t['remain_quota'] ?? 0) / 100).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
