import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class RedemptionPage extends StatefulWidget {
  const RedemptionPage({super.key});
  @override
  State<RedemptionPage> createState() => _RedemptionPageState();
}

class _RedemptionPageState extends State<RedemptionPage> {
  final _client = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/redemption/', queryParameters: {'p': 0, 'size': 50});
      if (res.data['success'] == true && mounted) {
        setState(() { _items = res.data['data'] ?? []; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('兑换码管理'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _items.isEmpty
          ? const Center(child: Text('暂无兑换码'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (_, idx) {
                final r = _items[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: Text(r['key'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                    subtitle: Text('额度: \$${((r['quota'] ?? 0) / 100).toStringAsFixed(2)}'),
                    trailing: Chip(label: Text(r['status'] == 1 ? '未使用' : '已使用', style: const TextStyle(fontSize: 12))),
                  ),
                );
              },
            ),
    );
  }
}