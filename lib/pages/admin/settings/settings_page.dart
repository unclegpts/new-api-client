import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _client = ApiClient();
  Map<String, dynamic>? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.dio.get('/api/status');
      if (res.data['success'] == true && mounted) {
        setState(() { _status = res.data['data']; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await _client.dio.post('/api/setting/update', data: {key: value.toString()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('系统设置'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('运营设置', Icons.settings, [
            _buildField('系统名称', _status?['system_name'] ?? '', (v) => _saveSetting('system_name', v)),
            _buildField('Logo URL', _status?['logo'] ?? '', (v) => _saveSetting('logo', v)),
            _buildField('首页公告', _status?['notice'] ?? '', (v) => _saveSetting('notice', v), multiline: true),
          ]),
          const SizedBox(height: 16),
          _buildSection('功能开关', Icons.toggle_on, [
            _buildToggle('启用注册', _status?['register_enabled'] == true, (v) => _saveSetting('register_enabled', v)),
            _buildToggle('启用绘图', _status?['enable_drawing'] == true, (v) => _saveSetting('enable_drawing', v)),
            _buildToggle('启用任务', _status?['enable_task'] == true, (v) => _saveSetting('enable_task', v)),
            _buildToggle('启用数据导出', _status?['enable_data_export'] == true, (v) => _saveSetting('enable_data_export', v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('模型配置', Icons.model_training, [
            _buildField('默认模型', _status?['default_model'] ?? '', (v) => _saveSetting('default_model', v)),
            _buildField('全局 Temperature', (_status?['default_temperature'] ?? 0.7).toString(), (v) => _saveSetting('default_temperature', v)),
            _buildField('全局 Max Tokens', (_status?['default_max_tokens'] ?? 2048).toString(), (v) => _saveSetting('default_max_tokens', v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('支付配置', Icons.payments, [
            _buildField('支付网关', _status?['payment_gateway'] ?? '无', (v) => _saveSetting('payment_gateway', v)),
            _buildField('Stripe Key', _mask(_status?['stripe_key']), (v) => _saveSetting('stripe_key', v)),
            _buildField('EPay URL', _status?['epay_url'] ?? '', (v) => _saveSetting('epay_url', v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('限流配置', Icons.speed, [
            _buildField('每用户 RPM', (_status?['user_rpm'] ?? 60).toString(), (v) => _saveSetting('user_rpm', v)),
            _buildField('每 IP RPM', (_status?['ip_rpm'] ?? 60).toString(), (v) => _saveSetting('ip_rpm', v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('安全设置', Icons.security, [
            _buildField('敏感词 (逗号分隔)', (_status?['sensitive_words'] as List?)?.join(',') ?? '', (v) => _saveSetting('sensitive_words', v)),
            _buildToggle('启用 OAuth', _status?['oauth_enabled'] == true, (v) => _saveSetting('oauth_enabled', v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('服务器信息', Icons.info, [
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('版本'),
              subtitle: Text(_status?['version'] ?? '未知'),
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('启动时间'),
              subtitle: Text(_status?['start_time'] ?? '未知'),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ]),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  String _mask(dynamic v) {
    if (v == null || v.toString().isEmpty) return '未设置';
    final s = v.toString();
    if (s.length <= 8) return '****';
    return '${s.substring(0, 4)}...${s.substring(s.length - 4)}';
  }

  Widget _buildField(String label, String value, Function(String) onSave, {bool multiline = false}) {
    final ctrl = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
              maxLines: multiline ? 3 : 1,
            ),
          ),
          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => onSave(ctrl.text), tooltip: '保存'),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onToggle) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onToggle,
      dense: true,
    );
  }
}
