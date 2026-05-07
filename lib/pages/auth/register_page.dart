import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _client = ApiClient();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请填写所有字段');
      return;
    }
    if (password != confirm) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.post('/api/user/register', data: {
        'username': username, 'password': password,
      });
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录')),
        );
        context.go('/login');
      } else {
        setState(() => _error = res.data['message'] ?? '注册失败');
      }
    } catch (e) {
      setState(() => _error = '网络错误');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: '确认密码', border: OutlineInputBorder())),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: _loading ? null : _register, child: const Text('注 册'))),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.go('/login'), child: const Text('已有账号？去登录')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
