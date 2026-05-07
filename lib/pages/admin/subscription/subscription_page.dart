import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _client = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/subscription/', queryParameters: {'p': 0, 'size': 50});
      if (res.data['success'] == true && mounted) {
        setState(() { _items = res.data['data'] ?? []; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅管理'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty
          ? const Center(child: Text('暂无订阅'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (_, idx) {
                final s = _items[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: const Icon(Icons.subscriptions),
                    title: Text(s['name'] ?? s['plan_name'] ?? '订阅'),
                    subtitle: Text('用户: ${s['username'] ?? '未知'}  |  \$${((s['price'] ?? 0) / 100).toStringAsFixed(2)}'),
                    trailing: Chip(label: Text(s['status'] == 1 ? '有效' : '过期', style: const TextStyle(fontSize: 12))),
                  ),
                );
              },
            ),
    );
  }
}