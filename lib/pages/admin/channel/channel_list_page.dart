import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  final _client = ApiClient();
  List<dynamic> _channels = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.get('/api/channel/', queryParameters: {'p': 0, 'size': 50});
      if (res.data['success'] == true && mounted) {
        setState(() { _channels = res.data['data'] ?? []; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此渠道吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _client.dio.post('/api/channel/delete', data: {'id': id});
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
    }
  }

  Future<void> _showEditDialog([Map<String, dynamic>? channel]) async {
    final nameCtrl = TextEditingController(text: channel?['name'] ?? '');
    final keyCtrl = TextEditingController(text: channel?['key'] ?? '');
    final baseCtrl = TextEditingController(text: channel?['base_url'] ?? '');
    final modelsCtrl = TextEditingController(text: (channel?['models'] as List?)?.join(',') ?? '');
    final isEdit = channel != null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑渠道' : '新增渠道'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: baseCtrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: modelsCtrl, decoration: const InputDecoration(labelText: 'Models (逗号分隔)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'name': nameCtrl.text,
              'key': keyCtrl.text,
              'base_url': baseCtrl.text,
              'models': modelsCtrl.text,
            }),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;

    try {
      final data = {
        'name': result['name'],
        'key': result['key'],
        'base_url': result['base_url'],
        'models': result['models']!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };
      if (isEdit) data['id'] = channel['id'];
      await _client.dio.post(isEdit ? '/api/channel/update' : '/api/channel/add', data: data);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('渠道管理'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('新增渠道'),
        onPressed: () => _showEditDialog(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8), Text(_error!),
                  const SizedBox(height: 8), FilledButton.tonal(onPressed: _load, child: const Text('重试')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _channels.length,
                    itemBuilder: (_, idx) {
                      final c = _channels[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${c['id'] ?? idx}', style: const TextStyle(fontSize: 14)),
                          ),
                          title: Text(c['name'] ?? '未命名'),
                          subtitle: Text('${c['base_url'] ?? ''}\nModels: ${c['models']?.length ?? 0}个', maxLines: 2, style: const TextStyle(fontSize: 12)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditDialog(c as Map<String, dynamic>)),
                              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _delete(c['id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
