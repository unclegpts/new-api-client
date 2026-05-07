import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key});
  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();
  List<dynamic> _channels = [];
  bool _loading = true;
  String _search = '';
  String? _statusFilter;
  int _page = 0;
  static const _pageSize = 30;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = <String, dynamic>{'p': _page, 'size': _pageSize};
      if (_search.isNotEmpty) p['keyword'] = _search;
      if (_statusFilter != null) p['status'] = _statusFilter;
      final res = await _client.dio.get('/api/channel/', queryParameters: p);
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'];
        setState(() {
          _channels = data is List ? data : (data?['data'] ?? data?['items'] ?? []);
          _total = data is Map ? (data['total'] ?? _channels.length) : _channels.length;
          _loading = false;
        });
      }
    } catch (_) { if (mounted) { setState(() => _loading = false); } }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认删除'), content: const Text('确定要删除此渠道吗？'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
    ]));
    if (ok != true) return;
    try { await _client.dio.post('/api/channel/delete', data: {'id': id}); _load(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败'))); }
  }

  Future<void> _testChannel(dynamic c) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('测试中...'), duration: Duration(seconds: 2)));
    try {
      final res = await _client.dio.get('/api/channel/test/${c['id']}');
      final ok = res.data['success'] == true;
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ 连接成功' : '❌ ${res.data['message'] ?? '失败'}'),
        backgroundColor: ok ? Colors.green : Colors.red,
      )); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ 测试失败'), backgroundColor: Colors.red)); }
  }

  void _showEditDialog([Map<String, dynamic>? channel]) {
    final nameCtrl = TextEditingController(text: channel?['name'] ?? '');
    final keyCtrl = TextEditingController(text: channel?['key'] ?? '');
    final baseCtrl = TextEditingController(text: channel?['base_url'] ?? '');
    final modelsCtrl = TextEditingController(text: (channel?['models'] as List?)?.join(',') ?? '');
    final isEdit = channel != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(isEdit ? '编辑渠道' : '新增渠道'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: baseCtrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: modelsCtrl, decoration: const InputDecoration(labelText: 'Models (逗号分隔)', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          try {
            final data = {
              'name': nameCtrl.text, 'key': keyCtrl.text,
              'base_url': baseCtrl.text,
              'models': modelsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
            };
            if (isEdit) data['id'] = channel['id'];
            await _client.dio.post(isEdit ? '/api/channel/update' : '/api/channel/add', data: data);
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (_) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red)); }
        }, child: const Text('保存')),
      ],
    ));
  }

  String _statusText(dynamic s) {
    switch (s?.toString()) { case '1': return '启用'; case '2': return '禁用'; case '3': return '维护'; default: return '未知'; }
  }
  Color _statusColor(dynamic s) {
    switch (s?.toString()) { case '1': return Colors.green; case '2': return Colors.red; case '3': return Colors.orange; default: return Colors.grey; }
  }

  Widget _buildPagination() {
    final pages = _total == 0 ? 1 : (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.first_page, size: 20), onPressed: _page > 0 ? () { _page = 0; _load(); } : null),
        IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _page > 0 ? () { _page--; _load(); } : null),
        Text('${_page + 1}/$pages ($_total)', style: const TextStyle(fontSize: 12)),
        IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _page < pages - 1 ? () { _page++; _load(); } : null),
        IconButton(icon: const Icon(Icons.last_page, size: 20), onPressed: _page < pages - 1 ? () { _page = pages - 1; _load(); } : null),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('渠道管理'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add), label: const Text('新增渠道'), onPressed: () => _showEditDialog()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(hintText: '搜索...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 8)),
                onChanged: (v) { _search = v; _page = 0; _load(); },
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              value: _statusFilter,
              underline: const SizedBox(),
              hint: const Text('状态', style: TextStyle(fontSize: 12)),
              items: const [
                DropdownMenuItem(value: null, child: Text('全部', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: '1', child: Text('启用', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: '2', child: Text('禁用', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) { _statusFilter = v; _page = 0; _load(); },
            ),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator()) : _channels.isEmpty
            ? const Center(child: Text('暂无渠道'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                itemCount: _channels.length,
                itemBuilder: (_, i) {
                  final c = _channels[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: _statusColor(c['status']).withAlpha(30), child: Icon(Icons.cable, color: _statusColor(c['status']), size: 20)),
                      title: Text(c['name'] ?? '未命名', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['base_url'] ?? '', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Chip(label: Text(_statusText(c['status']), style: TextStyle(fontSize: 10, color: _statusColor(c['status']))), backgroundColor: _statusColor(c['status']).withAlpha(20), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          const SizedBox(width: 4),
                          Text('${c['models']?.length ?? 0}个模型', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ]),
                      ]),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) { switch(v) { case 'edit': _showEditDialog(c as Map<String, dynamic>); case 'test': _testChannel(c); case 'delete': _delete(c['id']); } },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit, size: 18), title: const Text('编辑'), dense: true)),
                          PopupMenuItem(value: 'test', child: ListTile(leading: const Icon(Icons.network_check, size: 18), title: const Text('测试连通'), dense: true)),
                          PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete, color: Colors.red, size: 18), title: const Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
        if (!_loading) _buildPagination(),
      ]),
    );
  }
}
