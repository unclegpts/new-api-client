import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';

// ── 绘图日志页 (Midjourney/SD/DALL-E) ──────────────────
class MidjourneyPage extends StatefulWidget {
  const MidjourneyPage({super.key});

  @override
  State<MidjourneyPage> createState() => _MidjourneyPageState();
}

class _MidjourneyPageState extends State<MidjourneyPage> {
  final _client = ApiClient();
  final _dateFmt = DateFormat('MM-dd HH:mm:ss');
  final _colorIcon = {
    'IMAGINE': Icons.palette,
    'UPSCALE': Icons.zoom_in,
    'VARIATION': Icons.shuffle,
    'BLEND': Icons.blur_on,
    'DESCRIBE': Icons.description,
    'REROLL': Icons.replay,
    'PAN': Icons.swipe,
    'ZOOM': Icons.center_focus_strong,
  };

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
      final res = await _client.dio.get('/api/log/mj/',
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

  String _actionLabel(String? action) {
    switch (action?.toUpperCase()) {
      case 'IMAGINE': return '绘图';
      case 'UPSCALE': return '放大';
      case 'VARIATION': return '变体';
      case 'BLEND': return '融合';
      case 'DESCRIBE': return '图生文';
      case 'REROLL': return '重绘';
      case 'PAN': return '平移';
      case 'ZOOM': return '缩放';
      default: return action ?? '-';
    }
  }

  Color _actionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'IMAGINE': return Colors.blue;
      case 'UPSCALE': return Colors.orange;
      case 'VARIATION': return Colors.purple;
      case 'BLEND': return Colors.teal;
      case 'DESCRIBE': return Colors.indigo;
      case 'REROLL': return Colors.amber;
      case 'PAN': return Colors.cyan;
      case 'ZOOM': return Colors.pink;
      default: return Colors.grey;
    }
  }

  IconData _actionIcon(String? action) {
    return _colorIcon[action?.toUpperCase()] ?? Icons.help_outline;
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': case 'completed': return Colors.green;
      case 'failed': case 'error': return Colors.red;
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': case 'completed': return '完成';
      case 'failed': case 'error': return '失败';
      case 'pending': return '等待';
      case 'in_progress': return '进行中';
      case 'cancelled': return '取消';
      default: return s ?? '-';
    }
  }

  Widget _buildTable() {
    if (_logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.image, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无绘图记录', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
        columns: const [
          DataColumn(label: Text('时间')),
          DataColumn(label: Text('用户')),
          DataColumn(label: Text('操作')),
          DataColumn(label: Text('提示词/描述')),
          DataColumn(label: Text('状态')),
          DataColumn(label: Text('结果')),
        ],
        rows: _logs.map((log) {
          final imageUrls = _extractImages(log);
          final prompt = log['prompt'] ?? log['description'] ?? log['action_detail'] ?? '-';
          return DataRow(cells: [
            DataCell(Text(_fmtTime(log['created_at'] ?? log['submit_time']), style: const TextStyle(fontSize: 12))),
            DataCell(Text('${log['username'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Chip(
              avatar: Icon(_actionIcon(log['action']), size: 14, color: Colors.white),
              label: Text(_actionLabel(log['action']), style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: _actionColor(log['action']),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  prompt.toString(),
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('提示词'), content: SingleChildScrollView(child: Text(prompt.toString())),
              )),
            ),
            DataCell(Chip(
              label: Text(_statusLabel(log['status']), style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: _statusColor(log['status']),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
            DataCell(
              imageUrls.isNotEmpty
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    _buildThumb(imageUrls.first, '预览'),
                    if (imageUrls.length > 1) Text(' +${imageUrls.length - 1}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])
                : const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  List<String> _extractImages(dynamic log) {
    final urls = <String>[];
    // result_url 可能是单张图或 JSON 数组
    final result = log['result_url'] ?? log['image_url'] ?? log['result'];
    if (result is String && result.isNotEmpty) {
      if (result.startsWith('[') || result.startsWith('{')) {
        urls.add('🔗 JSON结果');
      } else if (result.startsWith('http')) {
        urls.add(result);
      }
    } else if (result is List) {
      for (var u in result) {
        if (u is String && u.startsWith('http')) urls.add(u);
      }
    }
    // 检查 image_urls 字段
    final imgUrls = log['image_urls'];
    if (imgUrls is List) {
      for (var u in imgUrls) {
        if (u is String && u.startsWith('http')) urls.add(u);
      }
    }
    return urls;
  }

  Widget _buildThumb(String url, String alt) {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.network(url, fit: BoxFit.contain),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ]),
      )),
      child: Tooltip(
        message: url,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(url, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32)),
        ),
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
      appBar: AppBar(title: const Text('绘图日志'), actions: [
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
