import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';

// ── 钱包管理页 ──────────────────────────────────────────
class TopupPage extends StatefulWidget {
  const TopupPage({super.key});

  @override
  State<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends State<TopupPage> {
  final _client = ApiClient();
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  final _searchCtrl = TextEditingController();

  List<dynamic> _topups = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  final int _pageSize = 15;
  int _total = 0;
  String _keyword = '';

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

  String get _endpoint => '/api/user/topup/self'; // 普通用户看自己的

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'p': _page, 'page_size': _pageSize};
      if (_keyword.isNotEmpty) params['keyword'] = _keyword;

      final res = await _client.dio.get(_endpoint, queryParameters: params);
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'];
        setState(() {
          _topups = data is List ? data : (data?['items'] ?? []);
          _total = data is Map ? (data['total'] ?? 0) : (data?.length ?? 0);
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
      final dt = DateTime.parse(ts.toString());
      return _dateFmt.format(dt);
    } catch (_) {
      try {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          (ts is int) ? ts * 1000 : int.parse(ts.toString()) * 1000);
        return _dateFmt.format(dt);
      } catch (_) { return ts.toString(); }
    }
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'expired': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _statusLabel(String? s) {
    switch (s?.toLowerCase()) {
      case 'success': return '成功';
      case 'pending': return '待支付';
      case 'failed': return '失败';
      case 'expired': return '已过期';
      default: return s ?? '-';
    }
  }

  String _paymentLabel(String? pm) {
    switch (pm?.toLowerCase()) {
      case 'alipay': return '支付宝';
      case 'wxpay': case 'wechat': return '微信';
      case 'stripe': return 'Stripe';
      case 'creem': return 'Creem';
      default: return pm ?? '-';
    }
  }

  Widget _buildTable() {
    if (_topups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无充值记录', style: TextStyle(color: Colors.grey)),
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
          DataColumn(label: Text('订单号')),
          DataColumn(label: Text('支付方式')),
          DataColumn(label: Text('充值额度'), numeric: true),
          DataColumn(label: Text('金额'), numeric: true),
          DataColumn(label: Text('状态')),
          DataColumn(label: Text('时间')),
        ],
        rows: _topups.map((o) {
          final isSub = o['amount'] == 0 || (o['trade_no']?.toString().startsWith('sub') ?? false);
          return DataRow(cells: [
            DataCell(
              SizedBox(width: 160, child: Text(o['trade_no']?.toString() ?? '-', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
            ),
            DataCell(Text(_paymentLabel(o['payment_method']), style: const TextStyle(fontSize: 12))),
            DataCell(
              isSub
                ? const Chip(label: Text('订阅套餐', style: TextStyle(fontSize: 10)), backgroundColor: Colors.purple, padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)
                : Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.monetization_on, size: 14, color: Colors.amber), const SizedBox(width: 4), Text('${o['amount'] ?? 0}', style: const TextStyle(fontSize: 12))]),
            ),
            DataCell(Text(o['money'] != null ? '¥${double.tryParse(o['money'].toString())?.toStringAsFixed(2) ?? o['money']}' : '-',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error))),
            DataCell(Chip(
              label: Text(_statusLabel(o['status']), style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: _statusColor(o['status']),
              padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
            DataCell(Text(_fmtTime(o['create_time'] ?? o['created_at']), style: const TextStyle(fontSize: 11))),
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
      appBar: AppBar(title: const Text('钱包管理'), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {
          showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('搜索订单'),
            content: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: '订单号')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              FilledButton(onPressed: () { _keyword = _searchCtrl.text; _page = 0; Navigator.pop(context); _load(); }, child: const Text('搜索')),
            ],
          ));
        }),
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
