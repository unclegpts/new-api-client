import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int _page = 0;
  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/token/', queryParameters: {'p': _page, 'size': _pageSize});
      if (res.data['success'] == true && mounted) {
        setState(() { _tokens = (res.data['data'] as List?) ?? []; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(dynamic token) async {
    try {
      await _client.dio.put('/api/token/', data: {'id': token['id'], 'status': token['status'] == 1 ? 2 : 1});
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失败'), backgroundColor: Colors.red));
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('删除令牌'), content: const Text('确定删除此令牌吗？'), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
    ]));
    if (ok != true) return;
    try {
      await _client.dio.delete('/api/token/$id');
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red));
    }
  }

  void _copyKey(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)));
  }

  void _showEdit(dynamic token) {
    final nameCtrl = TextEditingController(text: token?['name'] ?? '');
    final quotaCtrl = TextEditingController(text: (token?['remain_quota'] ?? 500000).toString());
    final modelsCtrl = TextEditingController(text: (token?['models'] as List?)?.join(',') ?? '');
    final isNew = token == null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(isNew ? '创建令牌' : '编辑令牌'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: quotaCtrl, decoration: const InputDecoration(labelText: '额度', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        TextField(controller: modelsCtrl, decoration: const InputDecoration(labelText: '可用模型 (逗号分隔)', border: OutlineInputBorder(), hintText: '留空=全部模型')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          try {
            final data = {'name': nameCtrl.text, 'remain_quota': int.tryParse(quotaCtrl.text) ?? 500000};
            if (modelsCtrl.text.isNotEmpty) data['models'] = modelsCtrl.text.split(',').map((s) => s.trim()).toList();
            if (isNew) {
              await _client.dio.post('/api/token/', data: data);
            } else {
              data['id'] = token['id'];
              await _client.dio.put('/api/token/', data: data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (_) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red));
          }
        }, child: const Text('保存')),
      ],
    ));
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('令牌管理'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add), label: const Text('创建令牌'),
        onPressed: () => _showEdit(null),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _tokens.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.vpn_key_off, size: 48, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
              const SizedBox(height: 8), const Text('暂无令牌'),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: _tokens.length,
              itemBuilder: (_, i) {
                final t = _tokens[i];
                final enabled = t['status'] == 1;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (enabled ? Colors.green : Colors.red).withAlpha(30),
                      child: Icon(Icons.vpn_key, color: enabled ? Colors.green : Colors.red, size: 20),
                    ),
                    title: Text(t['name'] ?? '未命名', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(_maskKey(t['key'] ?? ''), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'copy': _copyKey(t['key']); break;
                          case 'edit': _showEdit(t); break;
                          case 'toggle': _toggleStatus(t); break;
                          case 'delete': _delete(t['id']); break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'copy', child: ListTile(leading: const Icon(Icons.copy, size: 18), title: const Text('复制 Key'), dense: true)),
                        PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit, size: 18), title: const Text('编辑'), dense: true)),
                        PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(enabled ? Icons.block : Icons.check_circle, size: 18), title: Text(enabled ? '禁用' : '启用'), dense: true)),
                        PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete, color: Colors.red, size: 18), title: const Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
