import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});
  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage> {
  final _client = ApiClient();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/models');
      if (res.data['success'] == true && mounted) {
        setState(() { _data = res.data['data']; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型管理'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _data == null
          ? const Center(child: Text('暂无数据'))
          : ListView(
              padding: const EdgeInsets.all(8),
              children: _data!.entries.map((e) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    leading: const Icon(Icons.model_training),
                    title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${(e.value as List).length} 个模型'),
                    children: (e.value as List).map((m) => ListTile(
                      dense: true,
                      title: Text(m.toString(), style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                    )).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}