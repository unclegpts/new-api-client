import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});
  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/models');
      if (res.data['success'] == true && mounted) {
        setState(() { _data = res.data['data']; _loading = false; });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _showAddModel() {
    final groupCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加模型'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: '分组', border: OutlineInputBorder(), hintText: '如 default, vip')),
        const SizedBox(height: 8),
        TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: '模型名称', border: OutlineInputBorder(), hintText: '如 gpt-4')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          try {
            await _client.dio.post('/api/models/', data: {'group': groupCtrl.text, 'model': modelCtrl.text});
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            _load();
          } catch (_) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('添加失败'), backgroundColor: Colors.red)); }
        }, child: const Text('添加')),
      ],
    ));
  }

  Future<void> _deleteModel(String group, String model) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('删除模型'), content: Text('确定删除 $model 吗？'), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
    ]));
    if (ok != true) return;
    try {
      await _client.dio.delete('/api/models/', data: {'group': group, 'model': model});
      _load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red)); }
  }

  List<MapEntry<String, dynamic>> get _filteredEntries {
    if (_data == null) return [];
    var entries = _data!.entries.toList();
    if (_search.isNotEmpty) {
      entries = entries.where((e) {
        final models = (e.value as List?) ?? [];
        return e.key.toLowerCase().contains(_search.toLowerCase()) || models.any((m) => m.toString().toLowerCase().contains(_search.toLowerCase()));
      }).toList();
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型管理'), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: _ModelSearchDelegate(_data ?? {}))),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add), label: const Text('添加模型'), onPressed: _showAddModel),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _data == null
        ? const Center(child: Text('暂无数据'))
        : Column(children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(hintText: '搜索分组或模型...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
              children: _filteredEntries.map((e) {
                final models = (e.value as List?) ?? [];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    leading: const Icon(Icons.folder),
                    title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${models.length} 个模型'),
                    children: models.map((m) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.model_training, size: 18),
                      title: Text(m.toString(), style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _deleteModel(e.key, m.toString()), tooltip: '删除'),
                    )).toList(),
                  ),
                );
              }).toList(),
            )),
          ]),
    );
  }
}

class _ModelSearchDelegate extends SearchDelegate<String> {
  final Map<String, dynamic> data;
  _ModelSearchDelegate(this.data);

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  
  @override
  Widget buildResults(BuildContext context) => _buildSearchList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchList(context);

  Widget _buildSearchList(BuildContext context) {
    final results = <String>[];
    data.forEach((group, models) {
      if (models is List) {
        for (final m in models) {
          if (m.toString().toLowerCase().contains(query.toLowerCase()) || group.toLowerCase().contains(query.toLowerCase())) {
            results.add('$group → $m');
          }
        }
      }
    });
    return ListView(children: results.map((r) => ListTile(title: Text(r, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)))).toList());
  }
}
