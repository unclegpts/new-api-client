import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';

// ── 使用日志页 ──────────────────────────────────────────
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();

  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  final int _pageSize = 20;
  int _total = 0;
  String _keyword = '';
  String? _statusFilter; // null=all, 'success', 'failed'
  final _dateFmt = DateFormat('MM-dd HH:mm:ss');
  final _amountFmt = NumberFormat('#,##0', 'en_US');

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
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{
        'p': _page,
        'size': _pageSize,
      };
      if (_keyword.isNotEmpty) params['keyword'] = _keyword;
      if (_statusFilter != null) params['status'] = _statusFilter;

      final res = await _client.dio.get('/api/log/', queryParameters: params);
      if (res.data['success'] == true && mounted) {
        setState(() {
          _logs = res.data['data'] ?? [];
          _total = res.data['total'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  String _fmtTime(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch((ts is int) ? ts * 1000 : int.parse(ts.toString()) * 1000);
      return _dateFmt.format(dt);
    } catch (_) {
      return ts.toString();
    }
  }

  String _fmtQuota(dynamic q) {
    if (q == null || q == 0) return '0';
    final n = (q is int) ? q : int.tryParse(q.toString()) ?? 0;
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return _amountFmt.format(n);
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': return '成功';
      case 'failed': return '失败';
      default: return s ?? '未知';
    }
  }

  String _tokenText(dynamic log) {
    final pt = log['prompt_tokens'] ?? 0;
    final ct = log['completion_tokens'] ?? 0;
    return '${_formatNum(pt)} / ${_formatNum(ct)}';
  }

  String _formatNum(dynamic n) {
    final v = (n is int) ? n : int.tryParse(n.toString()) ?? 0;
    if (v >= 1000) return _amountFmt.format(v);
    return v.toString();
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _keyword = ''; _page = 0; _load(); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) { _keyword = v; _page = 0; _load(); },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: _statusFilter,
            underline: const SizedBox(),
            hint: const Text('状态'),
            items: const [
              DropdownMenuItem(value: null, child: Text('全部')),
              DropdownMenuItem(value: 'success', child: Text('成功')),
              DropdownMenuItem(value: 'failed', child: Text('失败')),
            ],
            onChanged: (v) { _statusFilter = v; _page = 0; _load(); },
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { _page = 0; _load(); }),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无记录', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
        columns: const [
          DataColumn(label: Text('时间')),
          DataColumn(label: Text('用户')),
          DataColumn(label: Text('模型')),
          DataColumn(label: Text('渠道ID')),
          DataColumn(label: Text('Token'), numeric: true),
          DataColumn(label: Text('配额'), numeric: true),
          DataColumn(label: Text('状态')),
        ],
        rows: _logs.map((log) {
          return DataRow(cells: [
            DataCell(Text(_fmtTime(log['created_at'] ?? log['timestamp']), style: const TextStyle(fontSize: 12))),
            DataCell(Text('${log['username'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${log['model_name'] ?? log['model'] ?? '-'}', style: const TextStyle(fontSize: 12)), onTap: () {
              showDialog(context: context, builder: (_) => AlertDialog(title: const Text('模型'), content: Text('${log['model_name'] ?? log['model']}')));
            }),
            DataCell(Text('${log['channel_id'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text(_tokenText(log), style: const TextStyle(fontSize: 12))),
            DataCell(Chip(label: Text(_fmtQuota(log['quota']), style: const TextStyle(fontSize: 11)))),
            DataCell(Chip(
              label: Text(_statusLabel(log['status']), style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: _statusColor(log['status']),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    final pages = (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.first_page), onPressed: _page > 0 ? () { _page = 0; _load(); } : null),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 0 ? () { _page--; _load(); } : null),
          Text('${_page + 1} / $pages  (共 $_total 条)', style: const TextStyle(fontSize: 13)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < pages - 1 ? () { _page++; _load(); } : null),
          IconButton(icon: const Icon(Icons.last_page), onPressed: _page < pages - 1 ? () { _page = pages - 1; _load(); } : null),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用日志'), actions: [
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _buildFilterBar()),
      ]),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildTable()),
          if (!_loading) _buildPagination(),
          if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
