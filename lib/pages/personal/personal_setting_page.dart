import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';

// ── 个人设置页 ──────────────────────────────────────────
class PersonalSettingPage extends StatefulWidget {
  const PersonalSettingPage({super.key});

  @override
  State<PersonalSettingPage> createState() => _PersonalSettingPageState();
}

class _PersonalSettingPageState extends State<PersonalSettingPage> {
  final _client = ApiClient();
  final _secureStore = const FlutterSecureStorage();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Profile
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _wechatCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();

  // Password
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  // User info
  Map<String, dynamic>? _user;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _wechatCtrl.dispose();
    _githubCtrl.dispose();
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.get('/api/user/self');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _user = res.data['data'];
          _displayNameCtrl.text = _user?['display_name'] ?? _user?['username'] ?? '';
          _emailCtrl.text = _user?['email'] ?? '';
          _wechatCtrl.text = _user?['wechat_id'] ?? '';
          _githubCtrl.text = _user?['github_id'] ?? '';
          _loading = false;
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _saving = true; });
    try {
      final res = await _client.dio.put('/api/user/self', data: {
        'display_name': _displayNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'wechat_id': _wechatCtrl.text.trim(),
        'github_id': _githubCtrl.text.trim(),
      });
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? '保存失败')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  Future<void> _changePassword() async {
    final oldPwd = _oldPwdCtrl.text.trim();
    final newPwd = _newPwdCtrl.text.trim();
    final confirm = _confirmPwdCtrl.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写所有密码字段')));
      return;
    }
    if (newPwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次新密码不一致')));
      return;
    }
    if (newPwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少 6 位')));
      return;
    }

    setState(() { _saving = true; });
    try {
      final res = await _client.dio.put('/api/user/self', data: {
        'password': oldPwd,
        'new_password': newPwd,
      });
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功')));
        _oldPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? '修改失败')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('修改失败')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出登录吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('退出')),
      ],
    ));
    if (ok != true) return;
    await _secureStore.delete(key: 'auth_token');
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_initialized) return Scaffold(body: Center(child: Text(_error ?? '未知错误')));

    return Scaffold(
      appBar: AppBar(title: const Text('个人设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 用户信息头部 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (_user?['username']?.toString().isNotEmpty == true) ? _user!['username'][0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_user?['username'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('ID: ${_user?['id'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('角色: ${_user?['role'] ?? 'user'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('基本信息', style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          const SizedBox(height: 8),

          TextField(
            controller: _displayNameCtrl,
            decoration: const InputDecoration(labelText: '显示名称', hintText: '设置你的显示名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: '邮箱', hintText: '绑定邮箱', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wechatCtrl,
            decoration: const InputDecoration(labelText: '微信', hintText: '绑定微信账号', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _githubCtrl,
            decoration: const InputDecoration(labelText: 'GitHub', hintText: '绑定 GitHub 账号', border: OutlineInputBorder()),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: const Text('保存信息'),
              onPressed: _saving ? null : _saveProfile,
            ),
          ),

          const SizedBox(height: 32),
          Text('修改密码', style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          const SizedBox(height: 8),

          TextField(
            controller: _oldPwdCtrl,
            decoration: const InputDecoration(labelText: '当前密码', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwdCtrl,
            decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPwdCtrl,
            decoration: const InputDecoration(labelText: '确认新密码', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset),
              label: const Text('修改密码'),
              onPressed: _saving ? null : _changePassword,
            ),
          ),

          const SizedBox(height: 32),
          Text('主题', style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('跟随系统'), icon: Icon(Icons.auto_mode)),
              ButtonSegment(value: ThemeMode.light, label: Text('浅色'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {ThemeMode.system},
            onSelectionChanged: (_) {},
          ),

          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('退出登录', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            onPressed: _logout,
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
