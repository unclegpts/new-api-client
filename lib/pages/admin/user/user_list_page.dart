import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';
  int _page = 0;
  static const _pageSize = 30;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = <String, dynamic>{'p': _page, 'size': _pageSize};
      if (_search.isNotEmpty) p['keyword'] = _search;
      final res = await _client.dio.get('/api/user/', queryParameters: p);
      if (res.data['success'] == true && mounted) {
        setState(() { _users = res.data['data'] ?? []; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _toggleStatus(dynamic u) async {
    try {
      await _client.dio.put('/api/user/manage', data: {'id': u['id'], 'status': u['status'] == 1 ? 2 : 1});
      _load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失败'), backgroundColor: Colors.red)); }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('删除用户'), content: const Text('确定删除该用户吗？此操作不可逆'), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
    ]));
    if (ok != true) return;
    try { await _client.dio.delete('/api/user/manage/$id'); _load(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red)); }
  }

  void _showEdit(dynamic u) {
    final nameCtrl = TextEditingController(text: u?['username'] ?? '');
    final emailCtrl = TextEditingController(text: u?['email'] ?? '');
    final quotaCtrl = TextEditingController(text: (u?['quota'] ?? 0).toString());
    String role = '${u?['role'] ?? 0}';

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑用户'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: '邮箱', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: quotaCtrl, decoration: const InputDecoration(labelText: '额度', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: role,
          decoration: const InputDecoration(labelText: '角色', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: '0', child: Text('普通用户')),
            DropdownMenuItem(value: '10', child: Text('管理员')),
          ],
          onChanged: (v) => role = v ?? role,
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          try {
            await _client.dio.put('/api/user/manage', data: {
              'id': u['id'], 'username': nameCtrl.text, 'email': emailCtrl.text,
              'quota': int.tryParse(quotaCtrl.text) ?? 0, 'role': int.tryParse(role) ?? 0,
            });
            if (!ctx.mounted) return;
            Navigator.pop(ctx); _load();
          } catch (_) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red)); }
        }, child: const Text('保存')),
      ],
    ));
  }

  String _roleText(dynamic role) {
    switch (role) { case 100: return 'Root'; case 10: return '管理员'; default: return '用户'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户管理'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(hintText: '搜索用户...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 8)),
            onChanged: (v) { _search = v; _page = 0; _load(); },
          ),
        ),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _users.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 48, color: Theme.of(context).colorScheme.primary.withAlpha(80)), const SizedBox(height: 8), const Text('暂无用户'),
        ])) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          itemCount: _users.length,
          itemBuilder: (_, i) {
            final u = _users[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(child: Text((u['username']?[0] ?? 'U').toUpperCase())),
                title: Text(u['username'] ?? '未知', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${u['email'] ?? ''}  |  ${_roleText(u['role'])}', style: const TextStyle(fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) { switch(v) { case 'edit': _showEdit(u); case 'toggle': _toggleStatus(u); case 'delete': _delete(u['id']); } },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit, size: 18), title: const Text('编辑'), dense: true)),
                    PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(u['status'] == 1 ? Icons.block : Icons.check_circle, size: 18), title: Text(u['status'] == 1 ? '禁用' : '启用'), dense: true)),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete, color: Colors.red, size: 18), title: const Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
                  ],
                ),
              ),
            );
          },
        )),
      ]),
    );
  }
}
