import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _client = ApiClient();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请输入邮箱');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.dio.post('/api/user/reset', data: {'email': email});
      if (res.data['success'] == true && mounted) {
        setState(() => _sent = true);
      } else {
        setState(() => _error = res.data['message'] ?? '发送失败');
      }
    } catch (e) {
      setState(() => _error = '网络错误');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('忘记密码')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent ? _buildSent(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        const Text('输入注册邮箱，我们将发送重置链接', style: TextStyle(fontSize: 15)),
        const SizedBox(height: 16),
        TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: '邮箱', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: _loading ? null : _sendReset, child: const Text('发送重置链接'))),
        const SizedBox(height: 8),
        TextButton(onPressed: () => context.go('/login'), child: const Text('返回登录')),
      ],
    );
  }

  Widget _buildSent(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.mark_email_read, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        const Text('邮件已发送', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('请检查邮箱并点击链接重置密码'),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.go('/login'), child: const Text('返回登录')),
      ],
    );
  }
}
