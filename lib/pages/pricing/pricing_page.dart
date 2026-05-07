import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

// ── 定价页 ──────────────────────────────────────────────
class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();

  Map<String, List<dynamic>> _vendorModels = {};
  List<String> _vendors = [];
  String _selectedVendor = 'all';
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final res = await _client.dio.get('/api/models/');
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'] as Map<String, dynamic>;
        final vendorMap = <String, List<dynamic>>{};
        final vendorSet = <String>{};
        final allModels = <dynamic>[];

        data.forEach((group, models) {
          if (models is List) {
            for (final m in models) {
              if (m is Map<String, dynamic>) {
                final vendor = _guessVendor(m['id']?.toString() ?? '');
                vendorMap.putIfAbsent(vendor, () => []).add(m);
                vendorSet.add(vendor);
                allModels.add(m);
              }
            }
          }
        });

        final sortedVendors = vendorSet.toList()..sort();
        sortedVendors.insert(0, 'all');
        vendorMap['all'] = allModels;

        setState(() {
          _vendorModels = vendorMap;
          _vendors = sortedVendors;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _guessVendor(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('gpt') || lower.contains('davinci') || lower.contains('o1') || lower.contains('o3')) return 'OpenAI';
    if (lower.contains('claude')) return 'Anthropic';
    if (lower.contains('gemini')) return 'Google';
    if (lower.contains('llama') || lower.contains('mixtral')) return 'Meta';
    if (lower.contains('qwen')) return 'Alibaba';
    if (lower.contains('glm')) return 'Zhipu';
    if (lower.contains('yi-')) return '01.AI';
    if (lower.contains('ernie') || lower.contains('wenxin')) return 'Baidu';
    if (lower.contains('deepseek')) return 'DeepSeek';
    if (lower.contains('moonshot') || lower.contains('kimi')) return 'Moonshot';
    if (lower.contains('doubao') || lower.contains('skylark')) return 'ByteDance';
    if (lower.contains('hunyuan')) return 'Tencent';
    if (lower.contains('baichuan')) return 'Baichuan';
    if (lower.contains('minimax')) return 'MiniMax';
    if (lower.contains('mistral')) return 'Mistral';
    if (lower.contains('command') || lower.contains('cohere')) return 'Cohere';
    if (lower.contains('palm') || lower.contains('bard')) return 'Google';
    if (lower.contains('titan') || lower.contains('nova')) return 'AWS';
    if (lower.contains('dall-e')) return 'OpenAI';
    if (lower.contains('midjourney')) return 'Midjourney';
    if (lower.contains('stable')) return 'Stability';
    return 'Other';
  }

  List<dynamic> get _filteredModels {
    var models = _vendorModels[_selectedVendor] ?? [];
    if (_search.isNotEmpty) {
      models = models.where((m) => m['id'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return models;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型定价'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索模型...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: _vendors.length <= 1 ? const Center(child: Text('暂无模型数据')) : Row(
        children: [
          // Vendor sidebar
          Container(
            width: 160,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: ListView(
              children: _vendors.map((v) => ListTile(
                dense: true,
                selected: _selectedVendor == v,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                title: Text(v, style: TextStyle(fontSize: 13, fontWeight: _selectedVendor == v ? FontWeight.bold : FontWeight.normal)),
                trailing: Text('${_vendorModels[v]?.length ?? 0}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                onTap: () => setState(() => _selectedVendor = v),
              )).toList(),
            ),
          ),
          // Model cards
          Expanded(
            child: _filteredModels.isEmpty
              ? const Center(child: Text('没有匹配的模型'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredModels.length,
                  itemBuilder: (_, i) {
                    final m = _filteredModels[i];
                    return _buildModelCard(m);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    final id = model['id'] ?? 'unknown';
    final description = model['description'] ?? model['object'] ?? '';
    final created = model['created'];
    final contextWindow = model['context_window'] ?? model['max_tokens'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                _buildVendorChip(),
              ],
            ),
            if (description is String && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Input', model['input_price'] ?? model['prompt_price'], Icons.text_fields),
                const SizedBox(width: 8),
                _buildInfoChip('Output', model['output_price'] ?? model['completion_price'], Icons.output),
                const SizedBox(width: 8),
                if (created != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 14),
                    label: Text('$created', style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (contextWindow != null && contextWindow != 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('上下文: ${_formatNum(contextWindow)} tokens', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorChip() {
    return Chip(
      avatar: Icon(_vendorIcon(_selectedVendor), size: 14),
      label: Text(_selectedVendor, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildInfoChip(String label, dynamic value, IconData icon) {
    final display = value != null ? '${_formatNum(value)}/M' : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12),
        const SizedBox(width: 4),
        Text('$label: $display', style: const TextStyle(fontSize: 10)),
      ]),
    );
  }

  IconData _vendorIcon(String vendor) {
    switch (vendor) {
      case 'OpenAI': return Icons.auto_awesome;
      case 'Anthropic': return Icons.psychology;
      case 'Google': return Icons.g_mobiledata;
      case 'Meta': return Icons.facebook;
      case 'Alibaba': return Icons.store;
      case 'DeepSeek': return Icons.search;
      case 'ByteDance': return Icons.tiktok;
      case 'Tencent': return Icons.wechat;
      default: return Icons.help_outline;
    }
  }

  String _formatNum(dynamic n) {
    if (n == null) return '-';
    if (n is num) {
      if (n >= 1) return n.toStringAsFixed(2);
      return n.toStringAsFixed(4);
    }
    return n.toString();
  }
}
