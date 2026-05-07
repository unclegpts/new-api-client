import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';

// ── 任务日志页 ──────────────────────────────────────────
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _client = ApiClient();
  final _dateFmt = DateFormat('MM-dd HH:mm:ss');

  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  final int _pageSize = 20;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.get('/api/log/task/',
        queryParameters: {'p': _page, 'size': _pageSize},
      );
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
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (ts is int) ? ts * 1000 : int.parse(ts.toString()) * 1000);
      return _dateFmt.format(dt);
    } catch (_) { return ts.toString(); }
  }

  String _typeLabel(String? t) {
    switch (t?.toLowerCase()) {
      case 'image': return '文生图';
      case 'video': return '文生视频';
      case 'audio': return '文生音乐';
      case 'text': return '文生文';
      default: return t ?? '-';
    }
  }

  Color _typeColor(String? t) {
    switch (t?.toLowerCase()) {
      case 'image': return Colors.blue;
      case 'video': return Colors.purple;
      case 'audio': return Colors.orange;
      case 'text': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      case 'pending': case 'in_progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': case 'completed': return '完成';
      case 'failed': return '失败';
      case 'pending': return '等待中';
      case 'in_progress': return '进行中';
      default: return s ?? '-';
    }
  }

  Widget _buildTable() {
    if (_logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.task, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无任务', style: TextStyle(color: Colors.grey)),
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
          DataColumn(label: Text('提交时间')),
          DataColumn(label: Text('完成时间')),
          DataColumn(label: Text('用户')),
          DataColumn(label: Text('类型')),
          DataColumn(label: Text('平台')),
          DataColumn(label: Text('状态')),
          DataColumn(label: Text('ID')),
        ],
        rows: _logs.map((log) {
          final progress = log['progress'];
          return DataRow(cells: [
            DataCell(Text(_fmtTime(log['submit_time'] ?? log['created_at']), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_fmtTime(log['finish_time'] ?? log['completed_at']), style: const TextStyle(fontSize: 12))),
            DataCell(Text('${log['username'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Chip(
              label: Text(_typeLabel(log['type']), style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: _typeColor(log['type']),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
            DataCell(Text('${log['platform'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(
              progress != null && progress is num && progress > 0 && progress < 100
                ? SizedBox(
                    width: 80,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      LinearProgressIndicator(value: progress / 100),
                      Text('${progress.round()}%', style: const TextStyle(fontSize: 10)),
                    ]),
                  )
                : Chip(
                    label: Text(_statusLabel(log['task_status'] ?? log['status']), style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: _statusColor(log['task_status'] ?? log['status']),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
            ),
            DataCell(
              GestureDetector(
                onTap: log['task_id'] != null ? () {
                  // todo: show detail
                } : null,
                child: Text('${log['task_id'] ?? log['id'] ?? '-'}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    final pages = _total == 0 ? 1 : (_total / _pageSize).ceil();
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
      appBar: AppBar(title: const Text('任务日志'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () { _page = 0; _load(); }),
      ]),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildTable()),
          if (!_loading) _buildPagination(),
          if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
