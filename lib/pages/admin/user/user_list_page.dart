import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _client = ApiClient();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/user/', queryParameters: {'p': 0, 'size': 50});
      if (res.data['success'] == true && mounted) {
        setState(() { _users = res.data['data'] ?? []; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String _roleText(dynamic role) {
    switch (role) { case 100: return 'Root'; case 10: return '管理员'; default: return '普通用户'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户管理'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _users.length,
        itemBuilder: (_, idx) {
          final u = _users[idx];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text((u['username']?[0] ?? 'U').toUpperCase())),
              title: Text(u['username'] ?? '未知'),
              subtitle: Text('${u['email'] ?? ''}  |  ${_roleText(u['role'])}'),
              trailing: Chip(label: Text(u['status'] == 1 ? '启用' : '禁用', style: const TextStyle(fontSize: 12)), backgroundColor: u['status'] == 1 ? Colors.green.shade50 : Colors.red.shade50),
            ),
          );
        },
      ),
    );
  }
}