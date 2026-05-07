import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

// ── 模型部署管理 ────────────────────────────────────────
class DeploymentPage extends StatefulWidget {
  const DeploymentPage({super.key});

  @override
  State<DeploymentPage> createState() => _DeploymentPageState();
}

class _DeploymentPageState extends State<DeploymentPage> {
  final _client = ApiClient();
  List<dynamic> _deployments = [];
  bool _loading = true;
  int _page = 0;
  final int _pageSize = 20;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final res = await _client.dio.get('/api/model_deployment/',
        queryParameters: {'p': _page, 'size': _pageSize});
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'];
        setState(() {
          _deployments = data is List ? data : (data?['items'] ?? []);
          _total = data is Map ? (data['total'] ?? 0) : 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('确认删除'),
      content: const Text('确定要删除此部署吗？此操作不可逆。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
      ],
    ));
    if (ok != true) return;
    try {
      await _client.dio.delete('/api/model_deployment/$id');
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red));
    }
  }

  String _statusLabel(String? s) {
    switch (s?.toLowerCase()) {
      case 'running': return '运行中';
      case 'stopped': return '已停止';
      case 'pending': return '等待中';
      case 'failed': return '失败';
      default: return s ?? '未知';
    }
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'running': return Colors.green;
      case 'stopped': return Colors.grey;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型部署'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () { _page = 0; _load(); }),
        IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
      ]),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _deployments.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.rocket_launch, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('暂无部署', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add), label: const Text('新建部署')),
              ]),
            )
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _deployments.length,
                  itemBuilder: (_, i) {
                    final d = _deployments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.rocket_launch, color: _statusColor(d['status'])),
                        title: Text(d['name']?.toString() ?? '未命名', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('模型: ${d['model'] ?? '-'}  |  平台: ${d['platform'] ?? '-'}  |  GPU: ${d['gpu_count'] ?? 0}'),
                          if (d['base_url'] != null) Text('URL: ${d['base_url']}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Chip(label: Text(_statusLabel(d['status']), style: const TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: _statusColor(d['status']), padding: EdgeInsets.zero),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _delete(d['id']), tooltip: '删除'),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              _buildPagination(),
            ]),
    );
  }

  Widget _buildPagination() {
    final pages = _total == 0 ? 1 : (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.first_page), onPressed: _page > 0 ? () { _page = 0; _load(); } : null),
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 0 ? () { _page--; _load(); } : null),
        Text('${_page + 1} / $pages  (共 $_total 条)', style: const TextStyle(fontSize: 13)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < pages - 1 ? () { _page++; _load(); } : null),
        IconButton(icon: const Icon(Icons.last_page), onPressed: _page < pages - 1 ? () { _page = pages - 1; _load(); } : null),
      ]),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String platform = 'ollama';

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('新建部署'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '部署名称', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: '模型名称', border: OutlineInputBorder(), hintText: '如 llama3:8b')),
          const SizedBox(height: 8),
          TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder(), hintText: 'http://localhost:11434')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: platform,
            decoration: const InputDecoration(labelText: '平台', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
              DropdownMenuItem(value: 'ionet', child: Text('io.net')),
              DropdownMenuItem(value: 'custom', child: Text('自定义')),
            ],
            onChanged: (v) => platform = v ?? platform,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          try {
            await _client.dio.post('/api/model_deployment/', data: {
              'name': nameCtrl.text,
              'model': modelCtrl.text,
              'base_url': urlCtrl.text,
              'platform': platform,
            });
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            _load();
          } catch (_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('创建失败'), backgroundColor: Colors.red));
          }
        }, child: const Text('创建')),
      ],
    ));
  }
}
