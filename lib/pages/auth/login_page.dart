import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _client = ApiClient();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _oauthProviders;
  bool _loadingProviders = true;
  bool _showPassword = false;
  bool _hasServerConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final url = await _client.getServerUrl();
    if (!mounted) return;
    setState(() => _hasServerConfigured = url != null && url.isNotEmpty);
    if (_hasServerConfigured) {
      _loadOAuthProviders();
    }
  }

  Future<void> _loadOAuthProviders() async {
    try {
      final res = await _client.dio.get('/api/oauth/state');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _oauthProviders = res.data['data'];
          _loadingProviders = false;
        });
      } else {
        if (mounted) setState(() => _loadingProviders = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await ref.read(authProvider.notifier).login(username, password);
    if (!mounted) return;
    if (result == true) {
      context.go('/console');
    } else if (result == false) {
      setState(() { _loading = false; _error = '登录失败，请检查用户名和密码'; });
    } else {
      setState(() { _loading = false; _error = '登录失败，请检查用户名和密码'; });
    }
  }

  void _passkeyLogin() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Passkey 登录'),
      content: const Text('Passkey (WebAuthn) 登录需要浏览器支持。\n在移动端使用生物识别，桌面端使用安全密钥。\n\nFeature coming soon.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    ));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    // 未配置服务器 — 显示配置引导
    if (!_hasServerConfigured) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: color.error),
                const SizedBox(height: 16),
                Text('未配置服务器', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('请先配置 new-api 服务器地址后再登录',
                    style: theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('配置服务器'),
                  onPressed: () => context.go('/setup'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.api, size: 56, color: color.primary),
                const SizedBox(height: 12),
                Text('登录 New API', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('连接到你的 AI 网关', style: theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
                const SizedBox(height: 32),

                // Account login
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: '用户名', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, size: 16, color: color.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: color.error, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('登 录'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('Passkey 登录'),
                  onPressed: _passkeyLogin,
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: () => context.go('/register'), child: const Text('注册账号')),
                    Text(' · ', style: TextStyle(color: color.onSurfaceVariant)),
                    TextButton(onPressed: () => context.go('/reset'), child: const Text('忘记密码')),
                  ],
                ),

                // OAuth section
                if (_loadingProviders)
                  const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                else if (_oauthProviders != null && (_oauthProviders as Map).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('或者', style: TextStyle(color: color.onSurfaceVariant, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  ..._buildOAuthButtons(color),
                ],

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/setup'),
                  child: const Text('切换服务器'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOAuthButtons(ColorScheme color) {
    final providers = _oauthProviders as Map<String, dynamic>;
    return providers.entries.map((e) {
      IconData icon;
      String label;
      Color? bgColor;
      switch (e.key) {
        case 'github': icon = Icons.code; label = 'GitHub 登录'; bgColor = const Color(0xFF24292e); break;
        case 'discord': icon = Icons.discord; label = 'Discord 登录'; bgColor = const Color(0xFF5865F2); break;
        case 'oidc': icon = Icons.fingerprint; label = 'OIDC 登录'; bgColor = color.tertiary; break;
        case 'linuxdo': icon = Icons.forum; label = 'LinuxDO 登录'; bgColor = const Color(0xFF4A90D9); break;
        default: icon = Icons.login; label = '${e.key} 登录'; bgColor = color.secondary;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            icon: Icon(icon, color: Colors.white, size: 20),
            label: Text(label, style: const TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(backgroundColor: bgColor),
            onPressed: () => _oauthLogin(e.key, e.value),
          ),
        ),
      );
    }).toList();
  }

  void _oauthLogin(String provider, dynamic config) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider OAuth 将在后续版本支持')),
    );
  }
}
