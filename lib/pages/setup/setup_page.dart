import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _urlController = TextEditingController();
  final _client = ApiClient();
  bool _loading = false;
  String? _error;
  String? _savedUrl;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final url = await _client.getServerUrl();
    if (url != null && mounted) {
      setState(() {
        _urlController.text = url;
        _savedUrl = url;
      });
    }
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = '请输入服务器地址');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await _client.configure(baseUrl: url);
      final response = await _client.dio.get('/api/status');
      if (response.data['success'] == true) {
        await _client.setServerUrl(url);
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => _error = '服务器返回错误');
      }
    } catch (e) {
      setState(() => _error = '无法连接到服务器，请检查地址');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useUrl(String url) {
    _urlController.text = url;
    _connect();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Icon(Icons.cloud, size: 56, color: color.primary),
                  const SizedBox(height: 12),
                  Text('连接到 New API 服务器',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('统一管理和分发多种 LLM',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  // URL input
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'https://your-server.com',
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                      errorText: _error,
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _urlController.clear(),
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _connect(),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _connect,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('测试连接并保存'),
                    ),
                  ),

                  // Saved server — quick reconnect
                  if (_savedUrl != null && _savedUrl != _urlController.text) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.history, size: 18),
                      label: Text('恢复上次: $_savedUrl'),
                      onPressed: () {
                        _urlController.text = _savedUrl!;
                        setState(() {});
                      },
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Common examples
                  Text('试试这些地址：',
                      style: theme.textTheme.titleSmall?.copyWith(color: color.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  _ExampleChip('https://api.openai.com', 'OpenAI 官方'),
                  _ExampleChip('https://api.anthropic.com', 'Anthropic 官方'),
                  _ExampleChip('http://localhost:3000', '本地部署'),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Tips
                  _TipRow(Icons.info_outline,
                      'new-api 是一个 AI 模型网关，支持 OpenAI / Claude / Gemini 等格式互转。'),
                  const SizedBox(height: 8),
                  _TipRow(Icons.code, '服务器地址通常是你的 new-api Web 面板地址，例如 https://api.your-domain.com。'),
                  const SizedBox(height: 8),
                  _TipRow(Icons.security, '建议使用 HTTPS 确保数据传输安全。'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String url;
  final String label;
  const _ExampleChip(this.url, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          final page = context.findAncestorStateOfType<_SetupPageState>();
          page?._useUrl(url);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 14,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(url,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
